#!/usr/bin/env bash

set -exuo pipefail

INSTALL_DIR=/usr/local/opt/docker-lifecycle-listener

sudo rm -rf "$INSTALL_DIR"

LISTENER_SERVICE_NAME=uk.org.lidalia.docker-lifecycle-listener

if launchctl list | grep $LISTENER_SERVICE_NAME; then
  sudo launchctl unload /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist
fi
sudo rm -f /Library/LaunchDaemons/$LISTENER_SERVICE_NAME.plist

NOTIFIER_NAME=docker-lifecycle-notifier
set +e
docker rm -f $NOTIFIER_NAME 2>/dev/null
set -e
