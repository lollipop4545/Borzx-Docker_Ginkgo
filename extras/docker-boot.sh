#!/system/bin/sh
# Magisk/KernelSU service; launch as Termux so socket ownership uses its group.
LOG=/data/local/tmp/docker-boot.log
exec >> "$LOG" 2>&1
for attempt in $(seq 1 120); do
    [ "$(getprop sys.boot_completed)" = 1 ] && break
    sleep 5
done
[ "$(getprop sys.boot_completed)" = 1 ] || { echo 'Android boot timed out'; exit 1; }
TERMUX=/data/data/com.termux
LAUNCHER=$TERMUX/files/usr/bin/start-docker
[ -x "$LAUNCHER" ] || { echo "Missing executable: $LAUNCHER"; exit 1; }
TERMUX_UID=$(stat -c %u "$TERMUX") || exit 1
for attempt in $(seq 1 20); do
    echo "Docker boot attempt $attempt"
    if /system/bin/su "$TERMUX_UID" -c "$TERMUX/files/usr/bin/bash $LAUNCHER --watch"; then
        exit 0
    fi
    sleep 15
done
echo 'Docker boot retries exhausted; inspect this log and dockerd.log'
exit 1
