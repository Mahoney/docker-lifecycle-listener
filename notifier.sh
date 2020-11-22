#!/bin/sh
set -eu

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S) $1"
}

send() {
  message=$1
  host=$2
  port=$3
  log "Sending $message to $host $port"
  echo "$message" | nc "$host" "$port"
  log "Sent $message to $host $port"
}

main() {
  port=${1:-47200}
  host=${2:-host.docker.internal}

  send start "$host" "$port"

  trap 'send stop $host $port; [ $sleep_pid ] && kill "$sleep_pid" 2>/dev/null' HUP INT TERM

  sleep 9999 & sleep_pid=$!
  wait 2>/dev/null
}

main "$@"
