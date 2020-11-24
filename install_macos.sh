#!/usr/bin/env bash

set -euo pipefail

mkdir -p /usr/local/opt/docker-lifecycle-listener/sbin/
cp listener.sh /usr/local/opt/docker-lifecycle-listener/sbin/
mkdir -p /usr/local/etc/docker-lifecycle-listener.d/on_start
mkdir /usr/local/etc/docker-lifecycle-listener.d/on_stop

LISTENER_SERVICE_NAME=uk.org.lidalia.docker-lifecycle-listener

if launchctl list | grep $LISTENER_SERVICE_NAME; then
  launchctl stop $LISTENER_SERVICE_NAME
  launchctl unload /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist
fi
cp $LISTENER_SERVICE_NAME.plist /Library/LaunchDaemons/
launchctl load /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist
launchctl start $LISTENER_SERVICE_NAME

NOTIFIER_NAME=docker-lifecycle-notifier

docker build . -t $NOTIFIER_NAME
docker rm -f $NOTIFIER_NAME
docker run \
  --detach \
  --restart always \
  --name $NOTIFIER_NAME \
  $NOTIFIER_NAME
