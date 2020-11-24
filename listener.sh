#! /usr/bin/env bash

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S) $1"
}

docker_running() {
  docker info 1>/dev/null 2>&1
  return
}

run_on_start() {
  log "Running on start scripts"
}

run_on_stop() {
  log "Running on stop scripts"
}

unknown() {
  local cmd=$1
  log "Ignoring unknown command [$cmd]; accepts start and stop"
}

cleanup() {
  kill_descendants $$
}

function kill_descendants {
  declare children; children=$(pgrep -P "$1")
  for i in $children; do
    declare child="$i"
    kill_descendants "$child"
    kill "$child"
  done
}

main() {
  local script_dir=${1:?'You must pass a script directory'}
  local port=${2:-47200}
  if docker_running; then
    run_on_start "$script_dir"
  fi

  trap 'cleanup; exit 0' HUP INT TERM

  log "Listening for commands on port $port"
  while :; do
    while read -r cmd; do
      if [ "$cmd" ]; then
        case $cmd in
          'start') run_on_start "$script_dir" ;;
          'stop')  run_on_stop "$script_dir" ;;
          *)       unknown "$cmd" ;;
        esac
      fi
    done < <(nc -l "$port")
  done

  log 'Exiting'
}

main "$@"
