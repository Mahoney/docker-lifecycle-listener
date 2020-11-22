#! /usr/bin/env bash

log() {
  echo "$(date +%Y-%d-%mT%H:%M:%S) $1"
}

start() {
  log "Received start, running on start scripts"
}

stop() {
  log "Received stop, running on stop scripts"
}

unknown() {
  log "Ignoring unknown command [$cmd]; accepts start and stop"
}

main() {
	local port=${1:-47200}
	log "Listening for commands on port $port"
	while :; do
		while read -r cmd; do
			if [ "$cmd" ]; then
				case $cmd in
					'start') start   ;;
					'stop' ) stop    ;;
					*      ) unknown ;;
				esac
			fi
		done < <(nc -l "$port")
	done

	log 'Exiting'
}

main "$@"
