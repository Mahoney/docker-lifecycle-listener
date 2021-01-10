FROM alpine:3.12.3

COPY notifier.sh /sbin/notifier.sh
WORKDIR /sbin

ENTRYPOINT [ "./notifier.sh", "/var/run/docker-lifecycle-listener.sock" ]
