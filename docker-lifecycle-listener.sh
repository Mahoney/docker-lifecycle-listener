#! /usr/bin/env bash

valid_commands=("start" "stop")

log() {
  echo "$(date +%Y-%m-%dT%H:%M:%S%z) $1"
}

error() {
  log >&2 "$1"
}

contains_element() {
  local item="$1"
  shift
  local array=("$@")
  for array; do [[ "$array" == "$item" ]] && return 0; done
  return 1
}

running_as_root() {
  [ "$(id -u)" -eq 0 ]
}

os_is_macOS() {
  test "$(uname -s)" = 'Darwin'
}

owner_of() {
  local file=$1
  if os_is_macOS; then
    stat -L -f '%u' "$file"
  else
    stat -L -c '%u' "$file"
  fi
}

root_is_owner_of() {
  local file=$1
  [ "$(owner_of "$file")" -eq 0 ]
}

group_other_permissions() {
  local file=$1
  if os_is_macOS; then
    stat -L -f "%SMp%SLp" "$file"
  else
    local all_permissions; all_permissions=$(stat -L -c "%A" "$file")
    echo "${all_permissions: -6}"
  fi
}

only_owner_can_write_to() {
  local file=$1
  ! [[ "$(group_other_permissions "$file")" =~ w ]]
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

run_script() {
  local script=$1
  local script_name; script_name="$(basename "$script")"
  log "Running $script_name"
  if "$script"; then
    log "$script_name Succeeded"
  else
    log "$script_name Failed"
  fi
}

run_if_possible() {
  local possible_script=$1
  if [ -x "$possible_script" ]; then
    if permissions_are_ok_for "$possible_script"; then
      run_script "$possible_script"
    else
      log "Skipping $(basename "$possible_script"); must be owned by root and not writable by anyone else"
    fi
  else
    log "Skipping $(basename "$possible_script"); not executable"
  fi
}

is_empty_dir() {
  local dir="$1"
  [ -z "$(ls -A "$dir")" ]
}

run_on() {
  local command="$1"
  local script_dir="$2"

  log "Handling $command"

  local dir; dir="$script_dir/on_$command/"
  if [ -d "$dir" ]; then
    if ! is_empty_dir "$dir"; then
      for file in "$dir"/*; do
        run_if_possible "$file"
      done
    else
      log "$dir is empty"
    fi
  else
    log "$dir does not exist"
  fi

  log "Finished handling $command"
}

unknown() {
  local cmd=$1
  log "Ignoring unknown command [$cmd]; accepts start and stop"
}

cleanup() {
  set +e
  kill_descendants $$
  set -e
}

kill_descendants() {
  declare children; children=$(pgrep -P "$1")
  for i in $children; do
    declare child="$i"
    kill_descendants "$child"
    kill "$child" 2>/dev/null
  done
}

check_directory_permissions() {
  local dir=$1
  if [ -e "$dir" ] && ! permissions_are_ok_for "$dir"; then
    error "$dir must be owned by the root user & only writable by the root user for this script to be run as root"
    return 1
  fi
}

check_all_directory_permissions() {
  check_directory_permissions "$script_dir"
  for command in "${valid_commands[@]}"; do
    check_directory_permissions "$script_dir/on_$command"
  done
}

is_valid_command() {
  local command=$1
  contains_element "$command" "${valid_commands[@]}"
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
  IFS=$'\n\t'
  set -euo pipefail

  local script_dir=${1:?'You must pass a script directory'}
  local port=${2:-47200}

  check_all_directory_permissions

  if docker_running; then
    run_on start "$script_dir"
  else
    log "Docker not running at the moment"
  fi

  trap 'cleanup; log Stopped; exit 0' HUP INT TERM

  log "Listening for commands on port $port"

  while read -r command; do
    run_command "$command"
  done < <(nc -kl "$port")

  log 'Exiting'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
