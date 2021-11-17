#!/usr/bin/env bash

set -euo pipefail

NOTIFIER_NAME=docker-lifecycle-notifier

set +e
docker rm -f $NOTIFIER_NAME 2>/dev/null
set -e
docker build . -t $NOTIFIER_NAME
docker run \
  --detach \
  --restart always \
  --add-host=host.docker.internal:host-gateway \
  --name $NOTIFIER_NAME \
  $NOTIFIER_NAME
