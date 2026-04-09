k<div align="center">

```
███╗   ██╗██╗██████╗     ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
████╗  ██║██║██╔══██╗    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
██╔██╗ ██║██║██████╔╝    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
██║╚██╗██║██║██╔══██╗    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ 
██║ ╚████║██║██████╔╝    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═══╝╚═╝╚═════╝     ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
```

**The monster is officially ALIVE.**

[![Kernel](https://img.shields.io/badge/Kernel-Linux%206.8-blue?style=for-the-badge&logo=linux&logoColor=white)](https://kernel.org)
[![BusyBox](https://img.shields.io/badge/Userland-BusyBox-red?style=for-the-badge)](https://busybox.net)
[![Shell](https://img.shields.io/badge/Init-Shell%20Script-green?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Architecture](https://img.shields.io/badge/Arch-x86__64-orange?style=for-the-badge)](https://en.wikipedia.org/wiki/X86-64)

</div>

---

## 👹 What is NIB Linux?

**NIB Linux** is a minimalist Linux distribution built entirely from scratch — no Debian base, no Ubuntu layer, no training wheels. Just a raw Linux kernel, a statically linked userland, and pure determination.

This is not a hobby fork. This is an **OS built from first principles**: kernel compiled by hand, initramfs crafted manually, and a custom package manager written in shell. Every byte is intentional.

> *"Most people use Linux. We built one."*

---

## ⚡ Features

### 🧠 Core System
- **Vanilla Linux Kernel 6.8** — compiled from official sources with a custom configuration
- **Statically linked BusyBox** — a complete UNIX toolset in a single binary, zero runtime dependencies
- **Custom `initramfs`** — hand-crafted initial RAM filesystem, packed with `cpio` and compressed with `gzip`
- **Shell-powered init** — transparent, readable boot process with no systemd, no sysvinit, no magic

### 📦 Package Manager — `ns` (NIB System)
NIB Linux ships with its own package manager: `ns`. Simple, shell-based, and functional.

```sh
ns install cmatrix   # Download and install a package
```

**How it works:**
1. `ns` fetches a `.tar.gz` package from the NIB packages repository on GitHub
2. The archive is downloaded via `curl` with full HTTPS support
3. The package is extracted directly into the root filesystem `/`
4. Done. No dependency hell, no lock files, no daemons.

### 🌐 Networking
- **Automatic network initialization** on boot via `udhcpc`
- **Custom DHCP script** — prevents overwriting DNS settings, sets up routing manually
- **DNS pre-configured** to `8.8.8.8` (Google) for reliable resolution
- Works out of the box in **QEMU** with `-net user -net nic`

### 🔒 HTTPS Support
The bundled `curl` binary is statically compiled with **OpenSSL 3.3.0** — enabling full HTTPS support for package downloads from GitHub raw content.

- Protocol support: `http`, `https`, `ftp`, `ftps`, `smtp`, `imap`, and more
- No shared libraries required at runtime
- Binary size optimized with `strip`

---

## 🏗️ Architecture

```
NIB Linux Boot Flow
───────────────────────────────────────────────
  GRUB bootloader
      │
      ▼
  Linux Kernel 6.8 (bzImage)
      │
      ▼
  initramfs (cpio.gz)
      │
      ▼
  /init (shell script)
      ├── mount /proc, /sys, /dev
      ├── mkdir /tmp
      ├── ip link set eth0 up
      ├── udhcpc (custom DHCP script)
      ├── echo nameserver 8.8.8.8 > /etc/resolv.conf
      └── exec /bin/sh  ← you are here
```

```
Package Installation Flow (ns)
───────────────────────────────────────────────
  ns install <package>
      │
      ▼
  curl -L https://raw.githubusercontent.com/
       NickIBrody/nib-packages/main/<pkg>.tar.gz
      │
      ▼
  tar -xzf /tmp/<pkg>.tar.gz -C /
      │
      ▼
  Package installed into rootfs
```

---

## 🚀 Quick Start

### Prerequisites

```bash
sudo apt-get install build-essential cpio xorriso grub-pc-bin qemu-system-x86_64
```

### Build

```bash
git clone https://github.com/NickIBrody/nib-linux.git
cd nib-linux
./build_nib.sh
```

> **Note:** The kernel source (`sources/linux-6.8/`) and BusyBox must be compiled separately before running the build script. See the build section below.

### Run in QEMU

```bash
qemu-system-x86_64 -cdrom nib-linux.iso -m 256 -net user -net nic
```

### Inside NIB Linux

The system boots directly into a shell. Network comes up automatically.

```sh
# Install a package
ns install cmatrix

# Run it
cmatrix
```

---

## 📦 Package Repository

Packages are hosted at [NickIBrody/nib-packages](https://github.com/NickIBrody/nib-packages).

Each package is a `.tar.gz` archive that extracts into the root `/` of the system. Package structure mirrors the filesystem:

```
cmatrix.tar.gz
├── usr/
│   ├── bin/
│   │   └── cmatrix          ← statically linked binary
│   └── share/
│       └── terminfo/
│           └── l/
│               └── linux    ← terminal info for proper rendering
```

### Currently available packages

| Package | Description |
|---------|-------------|
| `cmatrix` | The iconic Matrix rain effect for your terminal |

---

## 🔧 Build Details

### Kernel Configuration
The kernel is compiled from **Linux 6.8** sources with a minimal configuration targeting:
- x86_64 architecture
- Basic hardware support (PCI, SATA, network)
- initramfs support
- No modules — everything compiled in

### BusyBox
BusyBox is compiled **statically** (`CONFIG_STATIC=y`) providing a full suite of UNIX utilities in a single binary: `sh`, `ls`, `cat`, `ip`, `udhcpc`, `tar`, `wget`, `ping`, and 200+ more.

### curl with OpenSSL
The `curl` binary is compiled from source against a statically built **OpenSSL 3.3.0**:

```bash
./configure \
  --with-openssl=/tmp/ssl-static \
  --disable-shared \
  --enable-static \
  --disable-ldap \
  LDFLAGS="-all-static -L/tmp/ssl-static/lib64"
```

Result: a single self-contained binary with full HTTPS, no shared library dependencies.

### ISO Generation
The bootable ISO is created with **GRUB** as the bootloader:

```bash
grub-mkrescue -o nib-linux.iso iso_root/
```

Boot sequence: GRUB → bzImage → initramfs → /init → /bin/sh

---

## 📁 Repository Structure

```
nib-linux/
├── rootfs/              # The entire root filesystem
│   ├── bin/             # Core binaries (busybox, curl, ns)
│   ├── etc/             # Config files (ssl certs, resolv.conf template)
│   ├── init             # The init script — heart of the OS
│   └── usr/             # User utilities and shared data
├── iso_root/            # ISO structure for GRUB
│   └── boot/
│       ├── vmlinuz      # Compiled kernel
│       ├── initrd.img   # Packed initramfs
│       └── grub/
│           └── grub.cfg
├── configs/             # Kernel and BusyBox configs
├── build_nib.sh         # Main build script
└── screenshots/         # Proof it's alive
```

---

## 🖼️ Screenshots

![NIB Linux booting in QEMU](screenshots/screenshots.png)

*NIB Linux v0.1 — booting in QEMU, ready to install packages*

---

## 🗺️ Roadmap

- [ ] More packages (`htop`, `vim`, `figlet`, ...)
- [ ] WiFi support (`wpa_supplicant`)
- [ ] Persistent storage (boot from USB with writable rootfs)
- [ ] Real hardware testing
- [ ] Package dependency resolution in `ns`
- [ ] NIB Linux installer

---

## 🤝 Contributing

Contributions are welcome. Fork the repo, open issues, submit pull requests.

Want to add a package? Check [nib-packages](https://github.com/NickIBrody/nib-packages) — packages are just `.tar.gz` archives that extract into `/`.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built from scratch. Runs on nothing. Does everything that matters.**

*NIB Linux — because the real OS was the kernel we compiled along the way.*

</div>
