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

**Borzx-Docker Kernel** is an audited custom Linux `4.14.357` kernel for **Xiaomi Redmi Note 8 / 8T (`ginkgo` / `willow`)** and **Xiaomi Trinket** devices, engineered specifically to turn aging Snapdragon 665 phones into dedicated, ultra-low-power **Docker & container microservers**.

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

## Verified Kernel Capabilities & `check-config.sh` Audit

This kernel has been audited on a physical Redmi Note 8 using Moby's official `check-config.sh` tool against the live `/proc/config.gz`. The complete 127-line report is available in [CHECK_CONFIG.md](./CHECK_CONFIG.md).

### 1. Kernel Namespaces
* `CONFIG_NAMESPACES=y`
* `CONFIG_USER_NS=y` (User namespaces for rootless containers)
* `CONFIG_PID_NS=y` (Process ID namespaces)
* `CONFIG_IPC_NS=y` (IPC namespaces)
* `CONFIG_UTS_NS=y` (UTS / hostname namespaces)
* `CONFIG_NET_NS=y` (Network namespaces)

### 2. Control Groups (cgroups v1 & v2) & Resource Limits
* `CONFIG_CGROUPS=y`
* `CONFIG_CGROUP_PIDS=y` (Process number limiting)
* `CONFIG_CGROUP_DEVICE=y` (Device whitelist isolation)
* `CONFIG_CGROUP_FREEZER=y`, `CONFIG_CGROUP_SCHED=y`, `CONFIG_CGROUP_CPUACCT=y`
* `CONFIG_FAIR_GROUP_SCHED=y`
* `CONFIG_CPUSETS=y`, `CONFIG_MEMCG=y`, `CONFIG_MEMCG_SWAP=y`, `CONFIG_MEMCG_SWAP_ENABLED=y`
* `CONFIG_BLK_CGROUP=y`
* `CONFIG_POSIX_MQUEUE=y` & `CONFIG_POSIX_MQUEUE_SYSCTL=y`
* `CONFIG_KEYS=y` & `CONFIG_SECCOMP_FILTER=y`
* *Note on CPU Limits:* `CONFIG_CFS_BANDWIDTH` is unavailable because this kernel uses Qualcomm's `SCHED_WALT` (Window-Assisted Load Tracking) scheduler, which mutually excludes CFS quotas.

### 3. Networking, Bridge, NAT & Netfilter
* `CONFIG_VETH=y` (Virtual Ethernet pairs)
* `CONFIG_BRIDGE=y`, `CONFIG_STP=y`, `CONFIG_BRIDGE_NETFILTER=y`, `CONFIG_DUMMY=y`
* `CONFIG_OVERLAY_FS=y` (Native overlay2 storage driver on f2fs / ext4)
* `CONFIG_NF_CONNTRACK=y`, `CONFIG_NF_CONNTRACK_IPV4=y`, `CONFIG_NF_CONNTRACK_IPV6=y`
* `CONFIG_NF_NAT=y`, `CONFIG_IP_NF_NAT=y`, `CONFIG_IP_NF_TARGET_MASQUERADE=y`, `CONFIG_IP_NF_TARGET_REDIRECT=y`
* `CONFIG_IP_NF_FILTER=y`, `CONFIG_IP6_NF_FILTER=y`, `CONFIG_IP6_NF_IPTABLES=y`, `CONFIG_IP6_NF_NAT=y`
* `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y`, `CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y`, `CONFIG_NETFILTER_XT_MATCH_IPVS=y`, `CONFIG_NETFILTER_XT_MARK=y`

### 4. IPVS Load Balancing Support
* `CONFIG_IP_VS=y` & `CONFIG_IP_VS_IPV6=y`
* `CONFIG_IP_VS_PROTO_TCP=y` & `CONFIG_IP_VS_PROTO_UDP=y`
* `CONFIG_IP_VS_RR=y`, `CONFIG_IP_VS_WRR=y`, `CONFIG_IP_VS_LC=y`
* *Note on Multi-Node Overlays:* IPVS handles Layer-4 transport load balancing. For multi-node Kubernetes/k3s setups, use host networking or flannel `host-gw` mode, as overlay encapsulation (`CONFIG_VXLAN`) is not enabled on this tree.

### 5. Accurate Embedded `IKCONFIG` (`/proc/config.gz`)
* `kernel/Makefile` is patched to embed `$(objtree)/.config` directly rather than the stock Qualcomm defconfig, allowing Docker and container runtimes to accurately inspect active capabilities.

---

## Android-Specific Gotchas & How We Address Them

Running Docker on Android involves several platform-specific hurdles that standard Linux kernels don't encounter:

1. **`CONFIG_ANDROID_PARANOID_NETWORK` is Absent (Disabled):**  
   Stock Android kernels restrict network socket creation to specific Android GIDs (e.g. `aid_inet`). In this kernel, paranoid network checks are removed, allowing containerized applications to open raw network sockets freely.
2. **`CONFIG_RT_GROUP_SCHED` is Disabled:**  
   When enabled, Android kernels fail to allocate real-time CPU quotas to containers, causing `docker run` to crash with `cpu.rt_runtime_us` errors. This is disabled in our tree.
3. **SELinux Works in `Enforcing` Mode:**  
   Docker functions with SELinux in **Enforcing** mode. You do *not* need to set `setenforce 0` or compromise device security.
4. **Android Policy-Routing Bridge Fix:**  
   Android routes network packets using multiple routing tables based on UID and interface. Packets arriving on `docker0` do not consult the `main` routing table by default, breaking published ports (`-p 8080:80`) and container-to-WAN traffic.  
   Our launch script automatically injects the two required policy routing rules:
   ```bash
   # Add main routing table lookup
   ip rule add pref 5000 from all lookup main
   # Route docker0 traffic through current uplink table
   ip rule add pref 5001 iif docker0 lookup <uplink_table>
   ```

---

## Quick Start & Verification

### 1. Launching Docker on Android
We provide a standalone, production-tested helper script in [`extras/start-docker.sh`](./extras/start-docker.sh).

Install it in Termux:
```bash
cp extras/start-docker.sh $PREFIX/bin/start-docker
chmod +x $PREFIX/bin/start-docker
```

Run it anytime as the regular Termux user:
```bash
start-docker
```
It automatically clears stale sockets, starts `dockerd` detached in the background (surviving terminal exit), applies the bridge routing rules, and configures socket permissions.

### 2. Verify Your Installation
In Termux:
```bash
# 1. Test basic container execution:
docker run --rm hello-world

# 2. Test bridge networking and port publishing:
docker run -d --name test-web -p 8080:80 nginx:alpine
curl http://127.0.0.1:8080
# (Access http://<phone-ip>:8080 from another PC on your Wi-Fi!)
docker rm -f test-web
```

---

## 24/7 Home Server Care: Battery & Idle Charging

Keeping a smartphone connected to a charger 24/7 at 100% capacity can cause battery degradation and swelling.

The **Qualcomm Snapdragon 665 PMIC (SMB5)** supports true **Hardware Bypass Charging (Power Path Management)**:
- **Sysfs node:** `/sys/class/power_supply/battery/charging_enabled`
- **Verified on `ginkgo`:** Writing `0` to `charging_enabled` while USB is connected transitions battery status to **"Not charging"** with **0mA battery drain** (`current_now = 0`). The phone runs entirely from the external USB rail without cycling the battery.

### Automated Battery Guard Loop
We provide [`extras/battery-guard.sh`](./extras/battery-guard.sh) to maintain the battery between 70% and 80%:

```bash
#!/system/bin/sh
LOW=70
HIGH=80
B=/sys/class/power_supply/battery

while true; do
    cap=$(cat $B/capacity)
    if [ "$cap" -ge "$HIGH" ]; then
        echo 0 > $B/charging_enabled
    elif [ "$cap" -le "$LOW" ]; then
        echo 1 > $B/charging_enabled
    fi
    sleep 60
done
```
*Alternatively, install the **ACC (Advanced Charging Controller)** module via Magisk, which uses these exact same kernel nodes.*

---

## Starting Docker on Boot

For a headless home server, you want Docker to start automatically when the phone boots.

We provide a boot service script in [`extras/docker-boot.sh`](./extras/docker-boot.sh). To install it with Magisk or KernelSU:
```bash
su -c 'cp extras/docker-boot.sh /data/adb/service.d/docker-boot.sh && chmod 755 /data/adb/service.d/docker-boot.sh'
```
This waits until Android finishes booting and Wi-Fi connects, then launches `start-docker` in the background.

---

## Tested Environments & Workloads

### Tested Hardware & ROMs
- **Device:** Xiaomi Redmi Note 8 (`ginkgo`) / Redmi Note 8T (`willow`)
- **Firmware:** Global / India / China vendor base
- **Android Versions:** Android 11, 12, 13, and 14 (tested on LineageOS 20 baseline)
- **Root Solutions:** Magisk 26.x - 30.x (Vanilla build) & KernelSU-Next (KSU build)
- **SELinux Mode:** Enforcing

### Verified Production Containers on 3GB/4GB RAM
- **Home Assistant** (`ghcr.io/home-assistant/home-assistant:latest`) — Smart home automation engine
- **Cloudflare Tunnel** (`cloudflare/cloudflared:latest`) — Secure zero-trust remote access without port forwarding
- **ESPHome** (`ghcr.io/esphome/esphome:latest`) — IoT firmware compiler & dashboard
- **Nginx / Caddy** — Lightweight reverse proxy with SSL
- **Pi-hole / AdGuard Home** — Network-wide DNS sinkhole

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
Compiled flashable zips are automatically packaged into `./releases/`.

---

## Changelog

### v0.5.0 (Initial Official Release)
- Enabled full Docker cgroups (`devices`, `pids`, `cpu`, `cpuset`, `memory`, `freezer`, `blkio`, and `POSIX_MQUEUE`).
- Enabled container networking (`veth`, `bridge`, `bridge-netfilter`, full IPv4/IPv6 NAT, and IPVS load balancing).
- Patched `kernel/Makefile` to embed compiled `.config` into `/proc/config.gz`.
- Bundled AnyKernel3 with clean 7-bit ASCII recovery banner for TWRP / OrangeFox.
- Added verified Qualcomm bypass charging documentation and `battery-guard.sh`.
- Added Android policy-routing network bridge fix in `extras/start-docker.sh`.
- Shipped both **Vanilla** and **KernelSU-Next + SUSFS** variants.

---

## Credits, Attribution & Moral Rights

### Maintainer & Docker Kernel Modder
- **Surakiat Sittisomboon (Borzx)** — **[@lollipop4545](https://github.com/lollipop4545)** | **[borzx.site](https://borzx.site)**

### Original Kernel Author & Moral Rights Attribution
- **[@Flopster101](https://github.com/Flopster101)** ([FloppyKernel Series](https://github.com/FlopKernel-Series/flop_trinket-mi_kernel)) — Original author and maintainer of **FloppyKernel** for Xiaomi Trinket (`ginkgo` / `willow` / `laurel_sprout`).
  > **Moral Rights Statement**: All moral rights and credit for the foundational kernel tree, Xiaomi Trinket hardware adaptations, backports, ramdisk feature detection logic, and the `ckbuild.sh` / `do_build.sh` build system architecture belong to **@Flopster101**. This project is a derivative Docker-enabled modification of FloppyKernel and gratefully acknowledges @Flopster101's original work.

### Additional Credits
- **[@osm0sis](https://github.com/osm0sis)** — [AnyKernel3](https://github.com/osm0sis/AnyKernel3) flashable zip framework.
- **Ghostrider** & **Adithya R.** — Original Quicksilver build script foundations.
- **Linux Kernel Organization**, **CAF / CLO**, and **LineageOS** contributors.

---

## License

This kernel source is licensed under the **GNU General Public License v2.0 (GPL-2.0)** — see [`COPYING`](./COPYING) for details. AnyKernel3 flasher scripts in [`AnyKernel3/`](./AnyKernel3) are licensed under the **GNU General Public License v3.0 (GPL-3.0)** — see [`AnyKernel3/LICENSE`](./AnyKernel3/LICENSE).
