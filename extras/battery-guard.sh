#!/system/bin/sh
# Run as root. Keep charging between LOW and HIGH percent.
LOW=${LOW:-70}
HIGH=${HIGH:-80}
B=/sys/class/power_supply/battery
fail() { echo "battery-guard: $*" >&2; exit 1; }
case $LOW:$HIGH in *[!0-9:]*|:*|*:) fail 'Thresholds must be integers' ;; esac
[ "$LOW" -ge 0 ] && [ "$LOW" -lt "$HIGH" ] && [ "$HIGH" -le 100 ] || fail 'Require 0 <= LOW < HIGH <= 100'
[ -r "$B/capacity" ] && [ -w "$B/charging_enabled" ] || fail 'Battery control nodes unavailable or not writable'
FLOCK=$(command -v flock || true)
if [ -z "$FLOCK" ] && [ -x /data/data/com.termux/files/usr/bin/flock ]; then
    FLOCK=/data/data/com.termux/files/usr/bin/flock
fi
[ -n "$FLOCK" ] || fail 'flock is required (install util-linux in Termux)'
(
    exec 9>/data/local/tmp/battery-guard.lock
    "$FLOCK" -n 9 || exit 0
    # Restore charging on a normal stop; power loss/SIGKILL cannot run traps.
    trap 'echo 1 > "$B/charging_enabled"; exit' INT TERM HUP
    while true; do
        cap=$(cat "$B/capacity") || { echo 'Cannot read battery capacity' >&2; sleep 60; continue; }
        case $cap in ''|*[!0-9]*) echo 'Invalid battery capacity' >&2; sleep 60; continue ;; esac
        if [ "$cap" -ge "$HIGH" ]; then
            echo 0 > "$B/charging_enabled" || exit 1
        elif [ "$cap" -le "$LOW" ]; then
            echo 1 > "$B/charging_enabled" || exit 1
        fi
        sleep 60
    done
) >>/data/local/tmp/battery-guard.log 2>&1 &
