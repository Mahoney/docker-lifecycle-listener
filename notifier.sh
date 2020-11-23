#!/bin/sh

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S) $1"
}

send() {
  message=$1
  host=$2
  port=$3
  log "Sending $message to $host $port"
  set +e
  if echo "$message" | nc -v -G 1 -w 1 "$host" "$port"; then
    log "Sent $message to $host $port"
  else
    log "Unable to send $message to $host $port"
  fi
  set -e
}

cleanup() {
  pid=$1
  set +e
  [ "$pid" ] && kill "$pid"
  set -e
}

main() {
  port=${1:-47200}
  host=${2:-host.docker.internal}

  send start "$host" "$port"

  trap 'send stop $host $port; cleanup "$sleep_pid"; exit 0' HUP INT TERM

  sleep 9999 & sleep_pid=$!
  wait 2>/dev/null
}

main "$@"
