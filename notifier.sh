#!/bin/sh

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S%Z) $1"
}

send() {
  message=$1
  socket=$2
  log "Sending $message to $socket"
  if echo "$message" | nc "local:$socket"; then
    log "Sent $message to $socket"
  else
    log "Unable to send $message to $socket"
  fi
}

cleanup() {
  pid=$1
  [ "$pid" ] && kill "$pid" 2>/dev/null
}

main() {
  socket=${1:-/var/run/docker-lifecycle-listener.sock}

  send start "$socket"

  trap 'send stop $socket; cleanup "$sleep_pid"; exit 0' HUP INT TERM

  sleep infinity & sleep_pid=$!
  wait 2>/dev/null
}

main "$@"
