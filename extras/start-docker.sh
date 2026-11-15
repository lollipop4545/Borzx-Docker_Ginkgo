#!/data/data/com.termux/files/usr/bin/bash
# Termux launcher. Run as the Termux user; --watch refreshes routing every 30s.
set -eo pipefail
T_PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
fail() { echo "start-docker: $*" >&2; exit 1; }

if [[ ${1:-} != --root ]]; then
    [[ $T_PREFIX =~ ^/[a-zA-Z0-9_./-]+$ ]] || fail 'Invalid PREFIX'
    command -v su >/dev/null || fail 'Root (su) is required'
    script=$(realpath "$0")
    [[ $script =~ ^/[a-zA-Z0-9_./-]+$ ]] || fail 'Install at a path without spaces or shell characters'
    watch=0
    case ${1:-} in '' ) ;; --watch) watch=1 ;; *) fail 'Usage: start-docker [--watch]' ;; esac
    exec su -c "'$T_PREFIX/bin/bash' '$script' --root '$T_PREFIX' '$(id -g)' '$watch'"
fi

[[ $(id -u) == 0 ]] || fail 'Root escalation failed'
PREFIX=$2
socket_group=$3
watch=$4
export PREFIX PATH="$PREFIX/bin:/system/bin:$PATH"
for cmd in docker dockerd ip flock setsid nohup awk; do
    command -v "$cmd" >/dev/null || fail "Missing command: $cmd"
done
mkdir -p "$PREFIX/var/run" "$PREFIX/var/log"
exec 9>"$PREFIX/var/run/start-docker.lock"
flock -w 40 9 || fail 'Another launcher holds the startup lock'

ensure_rule() {
    local priority=$1 expected=$2
    shift 2
    local existing
    existing=$(ip -4 rule show | awk -v p="$priority:" '$1 == p {$1=""; sub(/^ +/, ""); gsub(/[[:space:]]+/, " "); print}')
    if [[ -n $existing ]]; then
        [[ $existing == "$expected" ]] || fail "Routing priority $priority is occupied: $existing"
    else
        ip -4 rule add pref "$priority" "$@"
    fi
}
refresh_routes() {
    local table old
    table=$(ip -4 route show table all | awk '
        /^default / {for(i=1;i<=NF;i++) if($i=="table") {if(!first) first=$(i+1); if($0 ~ /dev wlan0( |$)/) {print $(i+1); found=1; exit}}}
        END {if(!found && first) print first}')
    [[ $table =~ ^[a-zA-Z0-9_-]+$ ]] || fail 'No usable uplink routing table; connect Wi-Fi or mobile data and retry'
    # Preserve the Android integration rules, but refuse unrelated priority conflicts.
    ensure_rule 5000 'from all lookup main' from all lookup main
    old=$(cat "$PREFIX/var/run/start-docker.uplink" 2>/dev/null || true)
    if [[ -n $old && $old != "$table" ]]; then
        ip -4 rule del pref 5001 iif docker0 lookup "$old" 2>/dev/null || true
    fi
    ensure_rule 5001 "from all iif docker0 lookup $table" iif docker0 lookup "$table"
    printf '%s\n' "$table" > "$PREFIX/var/run/start-docker.uplink"
}

refresh_routes
if ! pidof dockerd >/dev/null 2>&1; then
    rm -f "$PREFIX/var/run/docker.pid" "$PREFIX/var/run/docker.sock" \
        "$PREFIX/var/run/docker/containerd/containerd.pid" \
        "$PREFIX/var/run/docker/containerd/containerd.sock"
    # Close our lock descriptor in the daemon so it cannot retain the startup lock.
    nohup setsid dockerd </dev/null >"$PREFIX/var/log/dockerd.log" 2>&1 9>&- &
fi
ready=0
for ((i=0; i<30; i++)); do
    if docker -H "unix://$PREFIX/var/run/docker.sock" info >/dev/null 2>&1; then
        chown "root:$socket_group" "$PREFIX/var/run/docker.sock"
        chmod 660 "$PREFIX/var/run/docker.sock"
        ready=1
        break
    fi
    sleep 1
done
[[ $ready == 1 ]] || fail "Daemon not ready after 30s; see $PREFIX/var/log/dockerd.log"
echo "Docker is ready (log: $PREFIX/var/log/dockerd.log)"
flock -u 9
if [[ $watch == 1 ]]; then
    # Dedicated watcher lock prevents duplicate monitors without blocking manual starts.
    exec 8>"$PREFIX/var/run/start-docker-watch.lock"
    flock -n 8 || exit 0
    while sleep 30; do
        # A subshell contains failures so the next network transition can recover.
        ( refresh_routes ) || echo 'Routing refresh failed; retrying in 30s' >&2
    done
fi
