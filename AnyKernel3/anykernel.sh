### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Original FloppyKernel script by @Flopster101 (Moral Rights & Base Credit)
## Modified for Borzx-Docker Kernel by Surakiat Sittisomboon / Borzx (@lollipop4545 | https://borzx.site)

### AnyKernel setup
# global properties
properties() { '
kernel.string=Borzx-Docker v0.5.0b by @lollipop4545 (borzx.site) | Base: FloppyKernel (@Flopster101)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=ginkgo
device.name2=willow
supported.versions=10.0-16.0
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

ui_print "─────────────────────────────────────────"
ui_print " Borzx-Docker Kernel for Redmi Note 8/8T"
ui_print " Developer : Surakiat (Borzx)"
ui_print " GitHub    : github.com/lollipop4545"
ui_print " Website   : borzx.site"
ui_print " Base      : FloppyKernel (@Flopster101)"
ui_print "─────────────────────────────────────────"
ui_print " "

# boot install
ui_print "-> Unpacking boot image..."
split_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk

# Check if vendor isn't already mounted. This should make the detection work on flasher apps.
do_patch=1;
if [ ! -e /vendor/etc/fstab.qcom ]; then
	if [ -e /dev/block/by-name/vendor ]; then
		mount /dev/block/by-name/vendor /vendor
		if [ $? -ne 0 ]; then
			do_patch=0
		fi
	else
		# If the block device for vendor isn't present at that location, it might mean this a dynamic partitions ROM.
		mount /vendor
		if [ $? -ne 0 ]; then
			do_patch=0
		fi
	fi
fi

# Check for the presence of "first_stage_mount" in /vendor/etc/fstab only for /system or /vendor
if [ $do_patch -eq 1 ]; then
	if grep "first_stage_mount" /vendor/etc/fstab.qcom | grep -E -q '(/system|/vendor)'; then
		ui_print "-> Two-stage init ROM detected, patching cmdline..."
		patch_cmdline "tsinit" "tsinit"
	else
		ui_print "-> Legacy init ROM detected, no need to patch"
	fi
else
	ui_print "-> Skipping cmdline patch because vendor could not be mounted!"
fi

# Check if /cache is mounted, try to mount if not
cache_mounted=0;
if mountpoint -q /cache 2>/dev/null; then
  cache_mounted=1;
else
  if mount /cache 2>/dev/null; then
    cache_mounted=1;
  fi
fi

# Check for feature flags in /cache/fk_feat
fk_feat_legacy_timestamp=0
# fk_feat_uname_bpf_spoof=0

if [ "$cache_mounted" -eq 1 ] && [ -f /cache/fk_feat ]; then
  if grep -q "no_init_protection" /cache/fk_feat 2>/dev/null; then
    ui_print "-> Reloaded feature: Kill init protection"
    patch_cmdline "no_init_protection" "no_init_protection=1"
  fi

  if grep -q "legacy_timestamp_source" /cache/fk_feat 2>/dev/null; then
    ui_print "-> Reloaded feature: Legacy Timestamp Source"
    patch_cmdline "legacy_timestamp_source" "legacy_timestamp_source=1"
    fk_feat_legacy_timestamp=1
  fi

  if grep -q "uname_bpf_spoof" /cache/fk_feat 2>/dev/null; then
    ui_print "-> Reloaded feature: Linux version spoofing for BPF"
    patch_cmdline "uname_bpf_spoof" "uname_bpf_spoof=1"
    # fk_feat_uname_bpf_spoof=1
  fi

  if grep -q "no_msm_perf_boost" /cache/fk_feat 2>/dev/null; then
    ui_print "-> Reloaded feature: Nuke MSM Performance boosting"
    patch_cmdline "no_msm_perf_boost" "no_msm_perf_boost=1"
  fi

  if grep -q "warm_reboot" /cache/fk_feat 2>/dev/null; then
    ui_print "-> Reloaded feature: Forced warm reboot"
    patch_cmdline "warm_reboot" "warm_reboot=1"
  fi
fi

if [ -f /vendor/build.prop ]; then
  if grep -q -E 'MINT|mintdevice' /vendor/build.prop; then
    ui_print "-> HyperMINT ROM DETECTED, you might need the BpfSpoof patch!..."
  fi
fi

# Check for IR HAL type
if [ -f /vendor/bin/hw/android.hardware.ir-service.lineage ]; then
	ui_print "-> LIRC-based IR HAL detected"
else
	ui_print "-> Legacy spidev IR HAL detected"
	patch_cmdline "legacy_ir_hal" "legacy_ir_hal=1"
fi

# Get Android version from build.prop and set legacy_timestamp_source (only if not already set via fk_feat)
if [ "$fk_feat_legacy_timestamp" -eq 0 ]; then
  android_ver=$(file_getprop /system/build.prop ro.build.version.release)

  # Convert to integer (strip potential decimal points)
  android_ver=${android_ver%%.*}

  # Check if Android version is 11 or lower
  if [ "$android_ver" -le 11 ] 2>/dev/null; then
    patch_cmdline "legacy_timestamp_source" "legacy_timestamp_source=1"
    ui_print "-> Legacy timestamp workaround enabled"
  else
    patch_cmdline "legacy_timestamp_source" "legacy_timestamp_source=0"
    ui_print "-> Timestamp patch not needed"
  fi
fi

ui_print "-> Flashing Borzx-Docker boot image..."
flash_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
ui_print "-> Flashing DTBO image..."
flash_dtbo;
ui_print " "
ui_print "─────────────────────────────────────────"
ui_print " Borzx-Docker Kernel flashed successfully!"
ui_print " Docker & Container support is ready."
ui_print " Special thanks to @Flopster101 & osm0sis."
ui_print "─────────────────────────────────────────"
## end boot install
