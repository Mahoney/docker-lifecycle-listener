# Docker Lifecycle Listener

This is a little system to allow running arbitrary commands on start and stop of
the docker daemon.

## Table of contents

- [Purpose](#purpose)
- [How it works](#how-it-works)
  - [Security Considerations](#security-considerations)
- [Installation](#installation)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows](#windows)
- [Configuration](#configuration)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

## Purpose

I wanted to run some scripts on the host whenever docker starts up - notably 
setting up https://github.com/AlmirKadric-Published/docker-tuntap-osx - and 
could not find  any way of reliably catching that event in order to run 
tasks that would  only work if docker were running, and re-run them if I 
restarted docker, and  have them run as soon as possible after docker starts.

A possible use case is to start a script that listens to `docker events` - this 
call can only be started when docker is started, and will exit when docker 
stops.

## How it works

`docker-lifecycle-listener.sh` runs on the host machine and listens on port
47200 (by default).

A tiny docker container is set up to start on docker start, immediately send 
`start` to port 47200 on the host, then go to sleep. On being shutdown (which 
will happen when docker stops) it sends `stop` to port 47200 on the host. 

When `docker-lifecycle-listener.sh` receives `start` it runs each script in 
`<script_dir>/on_start` in alphabetical order. When it receives `stop` it runs 
each script in `<script_dir>/on_stop` in alphabetical order.

In addition, if docker is already running, `docker-lifecycle-listener.sh` will
run each script in `<script_dir>/on_start` in alphabetical order when 
`docker-lifecycle-listener.sh` starts up in order to ensure it does not miss 
the start of the notifier.

### Security Considerations

Obviously any process that runs arbitrary executables in a directory is an
attack vector for malicious exploitation. This is particularly so if it is
running as `root`. To mitigate this `docker-lifecycle-listener.sh` insists that,
if it is running as `root`, both the directories and the scripts must be owned
and only writable by `root`. A malicious actor will therefore need to get
elevated privileges in order to use this listener to run its code.

## Installation

### macOS
```bash
git clone git@github.com:Mahoney/docker-lifecycle-listener.git && \
cd docker-lifecycle-listener && \
./install_macos.sh
```

The listener will run on O/S startup as a launch daemon; logs can be found at
`/var/log/docker-lifecycle-listener.log`.

Scripts should be placed in
`/usr/local/etc/docker-lifecycle-listener.d/on_start/` and 
`/usr/local/etc/docker-lifecycle-listener.d/on_stop/`.

### Linux
This is manual at the moment...

Place `docker-lifecycle-listener.sh` in an appropriate place on your system
(perhaps `/opt/docker-lifecycle-listener/docker-lifecycle-listener.sh`?).

Set up your service runner to run `docker-lifecycle-listener.sh` on system
start. Its first argument is the script directory where you will place the start
and stop scripts (perhaps `/etc/docker-lifecycle-listener.d/`?).

Build and start the docker image & container:
```bash
docker build . -t docker-lifecycle-notifier
docker rm -f docker-lifecycle-notifier
docker run \
  --detach \
  --restart always \
  --name docker-lifecycle-notifier \
  --add-host host.docker.internal:host-gateway \
  docker-lifecycle-notifier
```

### Windows

Unsupported.

## Configuration

The notifier can take between zero and two arguments:
1) `hostname` to notify - default `host.docker.internal`
2) `port` to notify - default `47200`

The listener has one required and one optional argument:
1) `script_dir` - a directory containing an `on_start` and an `on_stop` 
   directory, each of which can contain 0..n executables
2) `port` to listen on - default `47200`

On macOS `script_dir` is `/usr/local/etc/docker-lifecycle-listener.d/`.

## Development

The notifier is intended to run on `busybox` so uses `sh` not `bash`.

Tests can be written in [Bats](https://github.com/sstephenson/bats) and run via
`./run_tests.sh`.

## Troubleshooting

You can get some feedback on the behaviour of the notifier using
```bash
docker logs docker-lifecycle-notifier
```

The listener logs to stdout; on macOS this is redirected to
`/var/log/docker-lifecycle-listener.log`. Behaviour on Linux will depend on how
you set it up.
