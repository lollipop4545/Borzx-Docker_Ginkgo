# Borzx-Docker Kernel (`v0.5.0b`) — Xiaomi Redmi Note 8 / 8T (`ginkgo` / `willow`)

```text
  ██████╗  ██████╗ ██████╗ ███████╗██╗  ██╗
  ██╔══██╗██╔═══██╗██╔══██╗╚══███╔╝╚██╗██╔╝
  ██████╔╝██║   ██║██████╔╝  ███╔╝  ╚███╔╝ 
  ██╔══██╗██║   ██║██╔══██╗ ███╔╝   ██╔██╗ 
  ██████╔╝╚██████╔╝██║  ██║███████╗██╔╝ ██╗
  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
      D O C K E R   K E R N E L   v0.5.0b
  ─────────────────────────────────────────
   Dev / Modder : Surakiat (Borzx)
   GitHub / Web : @lollipop4545 | borzx.site
   Base Kernel  : FloppyKernel (@Flopster101)
```

**Borzx-Docker Kernel** is a custom Linux `4.14.357` kernel for **Xiaomi Redmi Note 8 / 8T (`ginkgo` / `willow`)** and **Xiaomi Trinket** devices, engineered specifically to run **Docker Engine**, **containerd**, **Podman**, **LXC**, and rootless containers natively on Android / Linux environments.

Developed and maintained by **Surakiat Sittisomboon (Borzx)** — **[@lollipop4545](https://github.com/lollipop4545)** ([borzx.site](https://borzx.site)), built upon the **FloppyKernel** base by **[@Flopster101](https://github.com/Flopster101)**.

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
- `CONFIG_OVERLAY_FS=y`
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

## Flashing Process

The repository includes the bundled [`AnyKernel3`](./AnyKernel3) flasher template, pre-configured for `ginkgo` and `willow`.

### Supported Installation Methods
1. **Custom Recovery (TWRP / OrangeFox / LineageOS Recovery)**:
   - Reboot to Recovery.
   - Select **Install** (or **ADB Sideload**) and flash `Borzx-Docker_v.0.5.0b-Vanilla-ginkgo-*.zip`.
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
# Standard build for Redmi Note 8/8T (ginkgo)
bash do_build.sh ginkgo

# Clean build
bash do_build.sh ginkgo c
```
- The build script (`ckbuild.sh`) automatically fetches the required AOSP Clang & GCC binutils toolchains into `../toolchains/` if not already present.
- Compiled `Image.gz-dtb`, `dtb`, and `dtbo.img` are automatically packaged using the bundled [`AnyKernel3/`](./AnyKernel3) directory into a flashable `.zip` in both `../` and `./releases/`.

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
