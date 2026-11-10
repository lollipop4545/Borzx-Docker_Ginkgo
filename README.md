# Borzx-Docker Kernel (`v0.5.0`) — Xiaomi Redmi Note 8 / 8T (`ginkgo` / `willow`)

```text
  ██████╗  ██████╗ ██████╗ ███████╗██╗  ██╗
  ██╔══██╗██╔═══██╗██╔══██╗╚══███╔╝╚██╗██╔╝
  ██████╔╝██║   ██║██████╔╝  ███╔╝  ╚███╔╝ 
  ██╔══██╗██║   ██║██╔══██╗ ███╔╝   ██╔██╗ 
  ██████╔╝╚██████╔╝██║  ██║███████╗██╔╝ ██╗
  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
      D O C K E R   K E R N E L   v0.5.0
  ─────────────────────────────────────────
   Dev / Modder : Surakiat (Borzx)
   GitHub / Web : @lollipop4545 | borzx.site
   Base Kernel  : FloppyKernel (@Flopster101)
```

**Borzx-Docker Kernel** is a custom Linux `4.14.357` kernel for **Xiaomi Redmi Note 8 / 8T (`ginkgo` / `willow`)** and **Xiaomi Trinket** devices, engineered specifically to run **Docker Engine**, **containerd**, **Podman**, **LXC**, and rootless containers natively on Android / Linux environments.

Developed and maintained by **Surakiat Sittisomboon (Borzx)** — **[@lollipop4545](https://github.com/lollipop4545)** ([borzx.site](https://borzx.site)), built upon the **FloppyKernel** base by **[@Flopster101](https://github.com/Flopster101)**.

---

## Which Variant Should You Flash?

We provide two official builds in the [Releases](https://github.com/lollipop4545/Borzx-Docker_Ginkgo/releases) tab:

| Variant | Recommended For | Details |
|---|---|---|
| **Vanilla** | **Magisk / APatch Users (Default)** | The cleanest, most universal baseline. Compatible with all ROMs and existing root setups. **Flash this if your device already has Magisk!** |
| **KSUNext-SUSFS** | **KernelSU Users** | Embeds KernelSU-Next and SUSFS directly into the kernel image for built-in kernel-level root without Magisk. |

> [!WARNING]
> **Do not flash KernelSU over an existing Magisk installation!** Having both Magisk and KernelSU active simultaneously can lead to root conflicts and boot issues. If you already have Magisk, flash the **Vanilla** build.

---

## Features & Container Capabilities

In addition to all upstream **FloppyKernel** optimizations and hardware support for `ginkgo`/`willow` (Android 10 – 16, two-stage & legacy init, LIRC/spidev IR HAL auto-detection), **Borzx-Docker Kernel** enables the complete set of core Docker `check-config.sh` kernel requirements:

### 1. Kernel Namespaces
- `CONFIG_NAMESPACES=y`
- `CONFIG_USER_NS=y` (User namespaces for rootless containers)
- `CONFIG_PID_NS=y` (Process ID namespaces)
- `CONFIG_IPC_NS=y` (IPC namespaces)
- `CONFIG_UTS_NS=y` (UTS / hostname namespaces)
- `CONFIG_NET_NS=y` (Network namespaces)

### 2. Control Groups (cgroups) & Resource Controllers
- `CONFIG_CGROUPS=y`
- `CONFIG_CGROUP_PIDS=y` (Process number controller)
- `CONFIG_CGROUP_DEVICE=y` (Device whitelist controller)
- `CONFIG_CGROUP_FREEZER=y`, `CONFIG_CGROUP_SCHED=y`, `CONFIG_CGROUP_CPUACCT=y`
- `CONFIG_FAIR_GROUP_SCHED=y`
- `CONFIG_CPUSETS=y`, `CONFIG_MEMCG=y`, `CONFIG_MEMCG_SWAP=y`, `CONFIG_MEMCG_SWAP_ENABLED=y`
- `CONFIG_BLK_CGROUP=y`
- `CONFIG_POSIX_MQUEUE=y` & `CONFIG_POSIX_MQUEUE_SYSCTL=y`

### 3. Container Networking, Bridge, Overlay & Netfilter
- `CONFIG_VETH=y` (Virtual Ethernet pair device)
- `CONFIG_BRIDGE=y`, `CONFIG_STP=y`, `CONFIG_BRIDGE_NETFILTER=y`, `CONFIG_DUMMY=y`
- `CONFIG_OVERLAY_FS=y` (Native overlay2 storage driver)
- `CONFIG_NF_CONNTRACK=y`, `CONFIG_NF_CONNTRACK_IPV4=y`, `CONFIG_NF_CONNTRACK_IPV6=y`
- `CONFIG_NF_NAT=y`, `CONFIG_IP_NF_NAT=y`, `CONFIG_IP_NF_TARGET_MASQUERADE=y`, `CONFIG_IP_NF_TARGET_REDIRECT=y`
- `CONFIG_IP6_NF_FILTER=y`, `CONFIG_IP6_NF_IPTABLES=y`, `CONFIG_IP6_NF_NAT=y`
- `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y`, `CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y`, `CONFIG_NETFILTER_XT_MATCH_IPVS=y`, `CONFIG_NETFILTER_XT_MARK=y`

### 4. IPVS (IP Virtual Server) Load Balancing (Docker Swarm / Kubernetes)
- `CONFIG_IP_VS=y` & `CONFIG_IP_VS_IPV6=y`
- `CONFIG_IP_VS_PROTO_TCP=y` & `CONFIG_IP_VS_PROTO_UDP=y`
- `CONFIG_IP_VS_RR=y`, `CONFIG_IP_VS_WRR=y`, `CONFIG_IP_VS_LC=y`

### 5. Accurate Embedded `IKCONFIG` (`/proc/config.gz`)
- `kernel/Makefile` is patched so `/proc/config.gz` embeds the real compiled `$(objtree)/.config` rather than the static stock defconfig, allowing `docker info` and `check-config.sh` to accurately verify all enabled container flags at runtime.

---

## 24/7 Home Server Care: Battery & Idle Charging

If you are using your Redmi Note 8 as a 24/7 home server (e.g. running Home Assistant, Pi-hole, Cloudflare Tunnels, databases), keeping lithium-ion batteries plugged into a charger at 100% permanently can cause battery degradation and swelling.

The **Snapdragon 665 / trinket PMIC** includes hardware **Power Path Management (Idle / Bypass Charging)** supported by this kernel:
- **Sysfs node:** `/sys/class/power_supply/battery/charging_enabled`
- Writing `0` stops charging the battery, powering the device directly from the USB cable without battery wear.
- Writing `1` re-enables normal charging.

### Recommended Approaches:
1. **ACC (Advanced Charging Controller)**: Install the ACC module in Magisk. It will automatically stop charging at 75%–80% and resume when it drops to 70%.
2. **Simple Cron / Script**: Run a small background loop in Termux:
   ```bash
   # Stop charging when capacity >= 80%:
   su -c "echo 0 > /sys/class/power_supply/battery/charging_enabled"
   # Resume charging when capacity <= 70%:
   su -c "echo 1 > /sys/class/power_supply/battery/charging_enabled"
   ```

---

## Running Docker in Termux

When launching Docker on Android, remember that Magisk root (`su`) operates inside Android's `/system/bin` environment and does not inherit Termux's `$PATH` by default. `dockerd` needs Termux's `$PATH` to discover `containerd`.

### Launching Docker Daemon:
```bash
su -c '
export PATH=/data/data/com.termux/files/usr/bin:$PATH
chmod -R 755 /data/data/com.termux/files/usr/var/run 2>/dev/null
rm -f /data/data/com.termux/files/usr/var/run/docker.sock
rm -f /data/data/com.termux/files/usr/var/run/containerd/containerd.sock
dockerd &
'
```

### Checking Running Containers:
```bash
su -c "export PATH=/data/data/com.termux/files/usr/bin:\$PATH; docker ps"
```

---

## Flashing Process

The repository includes the bundled [`AnyKernel3`](./AnyKernel3) flasher template with a clean 7-bit ASCII recovery banner for TWRP and OrangeFox.

### Supported Installation Methods
1. **Custom Recovery (TWRP / OrangeFox / LineageOS Recovery)**:
   - Reboot to Recovery.
   - Select **Install** (or **ADB Sideload**) and flash your chosen `.zip`.
   - The installer displays the Borzx ASCII banner, automatically detects two-stage init vs. legacy init, IR HAL type, and Android version timestamp requirements, and flashes `boot` and `dtbo`.
   - Reboot to System.
2. **Kernel Flasher Apps (e.g., Horizon Kernel Flasher / Franco Kernel Manager)**:
   - Import and flash the AnyKernel3 `.zip` directly from Android (root required), then reboot.

---

## Building from Source

### Prerequisites (Ubuntu / WSL2)
```bash
sudo apt update
sudo apt install -y build-essential clang lld make git python3 bc flex bison \
    ccache libelf-dev pahole openssl libssl-dev perl zstd binutils libncurses-dev \
    lz4 brotli cpio kmod zip curl
```

### Compile & Package Flashable Zip
From the root of the repository:
```bash
# Build Vanilla (Default, for Magisk users)
bash do_build.sh ginkgo

# Build KernelSU variant
bash do_build.sh ginkgo k

# Clean build
bash do_build.sh ginkgo c
```
- Compiled `Image.gz-dtb`, `dtb`, and `dtbo.img` are automatically packaged into flashable `.zip` files in `./releases/`.

---

## Credits, Attribution & Moral Rights

### Maintainer & Docker Kernel Modder
- **Surakiat Sittisomboon (Borzx)** — **[@lollipop4545](https://github.com/lollipop4545)** | **[borzx.site](https://borzx.site)**
  - Docker & container kernel configuration (`ginkgo.config` / `trinket-perf_defconfig`), `IKCONFIG` build fix, AnyKernel3 Borzx-Docker packaging, and maintenance.

### Original Kernel Author & Moral Rights Attribution
- **[@Flopster101](https://github.com/Flopster101)** ([FloppyKernel Series](https://github.com/FlopKernel-Series/flop_trinket-mi_kernel)) — Original author and maintainer of **FloppyKernel** for Xiaomi Trinket (`ginkgo` / `willow` / `laurel_sprout`).
  > **Moral Rights Statement**: All moral rights and credit for the foundational kernel tree, Xiaomi Trinket hardware adaptations, backports, ramdisk feature detection logic, and the `ckbuild.sh` / `do_build.sh` build system architecture belong to **@Flopster101**. This project is a derivative Docker-enabled modification of FloppyKernel and gratefully acknowledges @Flopster101's original work.

### Additional Credits
- **[@osm0sis](https://github.com/osm0sis)** — [AnyKernel3](https://github.com/osm0sis/AnyKernel3) flashable zip framework.
- **Ghostrider** & **Adithya R.** — Original Quicksilver build script foundations.
- **Linux Kernel Organization**, **CAF / CLO**, and **LineageOS** contributors.

---

## License

This kernel source is licensed under the **GNU General Public License v2.0 (GPL-2.0)** — see [`COPYING`](./COPYING) for details. AnyKernel3 components in [`AnyKernel3/`](./AnyKernel3) are licensed under the **GNU General Public License v3.0 (GPL-3.0)** — see [`AnyKernel3/LICENSE`](./AnyKernel3/LICENSE).
