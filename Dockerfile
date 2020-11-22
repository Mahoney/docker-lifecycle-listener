FROM busybox

COPY notifier.sh /sbin/notifier.sh
WORKDIR /sbin

ENTRYPOINT [ "./notifier.sh" ]
