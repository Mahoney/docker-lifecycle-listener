#!/usr/bin/env bash

set -exuo pipefail

INSTALL_DIR=/usr/local/opt/docker-lifecycle-listener
BINARY_DIR="$INSTALL_DIR/sbin/"
BINARY=docker-lifecycle-listener.sh

sudo rm -rf "$INSTALL_DIR"
mkdir -p "$BINARY_DIR"
cp "$BINARY" "$BINARY_DIR"
chmod u=rx,g=rx,o=rx "$BINARY_DIR/$BINARY"

SCRIPT_DIR=/usr/local/etc/docker-lifecycle-listener.d

mkdir -p "$SCRIPT_DIR/on_start"
mkdir -p "$SCRIPT_DIR/on_stop"

chmod -R u=rwx,g=rx,o=rx "$SCRIPT_DIR"
sudo chown -R root:wheel "$SCRIPT_DIR"

LISTENER_SERVICE_NAME=uk.org.lidalia.docker-lifecycle-listener

if launchctl list | grep $LISTENER_SERVICE_NAME; then
  sudo launchctl unload /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist
fi
sudo cp $LISTENER_SERVICE_NAME.plist /Library/LaunchDaemons/
launchctl load /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist
launchctl start $LISTENER_SERVICE_NAME

NOTIFIER_NAME=docker-lifecycle-notifier

set +e
docker rm -f $NOTIFIER_NAME 2>/dev/null
set -e
docker build . -t $NOTIFIER_NAME
docker run \
  --detach \
  --restart always \
  --name $NOTIFIER_NAME \
  $NOTIFIER_NAME
