#!/usr/bin/env bash

set -euo pipefail

mkdir -p /usr/local/opt/docker-lifecycle-listener/sbin/
cp listener.sh /usr/local/opt/docker-lifecycle-listener/sbin/

LISTENER_SERVICE_NAME=uk.org.lidalia.docker-lifecycle-listener
cp $LISTENER_SERVICE_NAME.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/$LISTENER_SERVICE_NAME.plist
launchctl start $LISTENER_SERVICE_NAME

NOTIFIER_NAME=docker-lifecycle-notifier

docker build . -t $NOTIFIER_NAME
docker rm -f $NOTIFIER_NAME
docker run \
  --detach \
  --restart always \
  --name $NOTIFIER_NAME \
  $NOTIFIER_NAME
