#!/usr/bin/env bash

set -euo pipefail

docker build . -t docker-lifecycle-listener
docker run \
  --detach \
  --restart always \
  --name docker-lifecycle-notifier \
  docker-lifecycle-notifier
