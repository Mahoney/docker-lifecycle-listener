#!/bin/sh

log() {
  echo "$(date +%Y-%m-%dT%H:%M:%S%z) $1"
}

send() {
  message=$1
  host=$2
  port=$3
  log "Sending $message to $host $port"
  if echo "$message" | nc -w 1 "$host" "$port"; then
    log "Sent $message to $host $port"
  else
    log "Unable to send $message to $host $port"
  fi
}

cleanup() {
  pid=$1
  [ "$pid" ] && kill "$pid" 2>/dev/null
}

main() {
  host=${1:-host.docker.internal}
  port=${2:-47200}

  send start "$host" "$port"

  trap 'send stop $host $port; cleanup "$sleep_pid"; exit 0' HUP INT TERM

  sleep infinity & sleep_pid=$!
  wait 2>/dev/null
}

main "$@"
