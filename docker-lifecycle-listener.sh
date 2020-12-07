#! /usr/bin/env bash

IFS=$'\n\t'
set -euo pipefail

declare valid_commands=("start" "stop")

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S) $1"
}

error() {
  log >&2 "$1"
}

containsElement() {
  local array="$1"
  local item="$2"
  for array; do [[ "$array" == "$item" ]] && return 0; done
  return 1
}

running_as_root() {
  [ "$(id -u)" -eq 0 ]
}

root_is_owner_of() {
  local file=$1
  local owner; owner=$(stat -f '%u' "$file")
  [ "$owner" -eq 0 ]
}

only_owner_can_write_to() {
  local file=$1
  local group_other_permissions; group_other_permissions=$(stat -f "%SMp%SLp" "$file")
  ! [[ "$group_other_permissions" =~ w ]]
}

permissions_are_ok_for() {
  local file=$1

  if running_as_root; then
    root_is_owner_of "$file" && only_owner_can_write_to "$file"
  fi
}

docker_running() {
  docker info 1>/dev/null 2>&1
}

run() {
  local script=$1
  log "Running $(basename "$script")"
  if "$script"; then
    log "Ran $(basename "$script")"
  else
    log "$(basename "$script") Failed"
  fi
}

run_if_possible() {
  local possible_script=$1
  if [ -x "$possible_script" ]; then
    if permissions_are_ok_for "$possible_script"; then
      run "$possible_script"
    else
      log "Skipping $(basename "$possible_script"); must be owned by root and not writable by anyone else"
    fi
  else
    log "Skipping $(basename "$possible_script"); not executable"
  fi
}

run_on() {
  local command="$1"
  local script_dir="$2"

  log "Received $command"

  local dir; dir=$(realpath "$script_dir/on_$command/")
  if [ -d "$dir" ]; then
    for file in "$dir"/*; do
      run_if_possible "$file"
    done
  else
    log "$dir does not exist"
  fi
}

unknown() {
  local cmd=$1
  log "Ignoring unknown command [$cmd]; accepts start and stop"
}

cleanup() {
  kill_descendants $$
}

kill_descendants() {
  declare children; children=$(pgrep -P "$1")
  for i in $children; do
    declare child="$i"
    kill_descendants "$child"
    kill "$child"
  done
}

check_directory_permissions() {
  for command in "${valid_commands[@]}"; do
    declare dir; dir="$script_dir/on_$command"
    if [ -e "$dir" ] && ! permissions_are_ok_for "$dir"; then
      error "$dir must be owned by the root user & only writable by the root user for this script to be run as root"
      return 1
    fi
  done
}

is_valid_command() {
  local command=$1
  containsElement "${valid_commands[@]}" "$command"
}

run_command() {
  local command=$1
  if is_valid_command "$command"; then
    run_on "$command" "$script_dir"
  else
    unknown "$command"
  fi
}

main() {
  local script_dir=${1:?'You must pass a script directory'}
  local port=${2:-47200}

  check_directory_permissions

  if docker_running; then
    run_on start "$script_dir"
  fi

  trap 'cleanup; exit 0' HUP INT TERM

  log "Listening for commands on port $port"
  while :; do
    while read -r command; do
      run_command "$command"
    done < <(nc -l "$port")
  done

  log 'Exiting'
}

main "$@"
