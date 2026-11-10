#!/system/bin/sh
# Magisk/KernelSU boot script: start Docker after Android finishes booting.
# Part of Borzx-Docker Kernel: https://github.com/lollipop4545/Borzx-Docker_Ginkgo
#
# Requires extras/start-docker.sh installed as $PREFIX/bin/start-docker in Termux.
# Install:
#   su -c 'cp docker-boot.sh /data/adb/service.d/docker-boot.sh && chmod 755 /data/adb/service.d/docker-boot.sh'

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 20   # let Wi-Fi come up so the uplink routing table exists

TERMUX_UID=$(stat -c %u /data/data/com.termux)
/system/bin/su "$TERMUX_UID" -c '/data/data/com.termux/files/usr/bin/bash -lc start-docker' \
    > /data/local/tmp/docker-boot.log 2>&1
