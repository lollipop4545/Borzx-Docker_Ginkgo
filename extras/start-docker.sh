#!/data/data/com.termux/files/usr/bin/bash
# start-docker - launch dockerd on Android (Termux + Magisk/KernelSU root)
# Part of Borzx-Docker Kernel: https://github.com/lollipop4545/Borzx-Docker_Ginkgo
#
# What it does:
#   1. Adds the policy-routing rules Android needs for Docker bridge networking
#      (without them, -p port publishing and outbound traffic from bridge containers fail)
#   2. Clears stale sockets/PIDs left over from an unclean shutdown
#   3. Starts dockerd detached (survives the terminal closing), logging to $PREFIX/var/log/dockerd.log
#   4. Waits until the daemon answers
#
# Install:  cp start-docker.sh $PREFIX/bin/start-docker && chmod +x $PREFIX/bin/start-docker
# Usage:    start-docker            (as the normal Termux user; uses su internally)

T_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

su -c "
export PREFIX=$T_PREFIX
export PATH=\$PREFIX/bin:/system/bin:\$PATH

if pidof dockerd >/dev/null 2>&1; then
    echo 'dockerd is already running'
else
    rm -f \$PREFIX/var/run/docker.pid \$PREFIX/var/run/docker.sock \
          \$PREFIX/var/run/docker/containerd/containerd.pid \
          \$PREFIX/var/run/docker/containerd/containerd.sock
    mkdir -p \$PREFIX/var/log
    nohup setsid dockerd </dev/null >\$PREFIX/var/log/dockerd.log 2>&1 &
fi

# Android routes packets by per-network policy tables, so traffic arriving on
# docker0 never consults the main table. Fix: let everything see the main table
# (only holds connected routes, so Android's per-app routing is unaffected), and
# send docker0 traffic through the table that holds the current default route.
ip rule show | grep -q 'pref 5000\|^5000:' || ip rule add pref 5000 from all lookup main
UPLINK_TABLE=\$(ip route show table all | grep -m1 '^default .*dev wlan0' | grep -o 'table [^ ]*' | cut -d' ' -f2)
[ -z \"\$UPLINK_TABLE\" ] && UPLINK_TABLE=\$(ip route show table all | grep -m1 '^default ' | grep -o 'table [^ ]*' | cut -d' ' -f2)
ip rule del pref 5001 2>/dev/null
[ -n \"\$UPLINK_TABLE\" ] && ip rule add pref 5001 iif docker0 lookup \$UPLINK_TABLE
"

for i in $(seq 1 30); do
    if su -c "$T_PREFIX/bin/docker -H unix://$T_PREFIX/var/run/docker.sock info" >/dev/null 2>&1; then
        su -c "chmod 660 $T_PREFIX/var/run/docker.sock; chown root:$(id -g) $T_PREFIX/var/run/docker.sock"
        echo "Docker is up (log: $T_PREFIX/var/log/dockerd.log)"
        exit 0
    fi
    sleep 1
done
echo "dockerd did not come up within 30s - see $T_PREFIX/var/log/dockerd.log"
exit 1
