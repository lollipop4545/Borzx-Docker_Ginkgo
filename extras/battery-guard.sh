#!/system/bin/sh
# battery-guard - keep the battery between LOW and HIGH percent on a 24/7 server
# Part of Borzx-Docker Kernel: https://github.com/lollipop4545/Borzx-Docker_Ginkgo
#
# Uses the Qualcomm SMB5 node /sys/class/power_supply/battery/charging_enabled.
# Verified on ginkgo: writing 0 with USB connected gives status "Not charging"
# and current_now 0 (the phone runs from USB; the battery does not drain).
#
# Run as root, e.g. as a Magisk/KernelSU boot script:
#   cp battery-guard.sh /data/adb/service.d/battery-guard.sh
#   chmod 755 /data/adb/service.d/battery-guard.sh
# Stop it any time with:  pkill -f battery-guard ; echo 1 > /sys/class/power_supply/battery/charging_enabled

LOW=${LOW:-70}
HIGH=${HIGH:-80}
B=/sys/class/power_supply/battery

(
while true; do
    cap=$(cat $B/capacity)
    if [ "$cap" -ge "$HIGH" ]; then
        echo 0 > $B/charging_enabled
    elif [ "$cap" -le "$LOW" ]; then
        echo 1 > $B/charging_enabled
    fi
    sleep 60
done
) &
