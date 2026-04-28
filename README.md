# NIB Linux

A minimal Linux distribution built from scratch — custom kernel, statically linked BusyBox userland, and a shell-powered init system.

## Features

- Linux 6.12 LTS kernel
- BusyBox userland
- WiFi support (Intel / Atheros / Broadcom / Realtek)
- TUI installer (`nib-install`) with disk selection and progress bar
- `wifi-connect` — connect to WiFi networks from the shell
- Custom package manager (`ns`)
- Boots on real hardware (UEFI + BIOS)

## Quick Start

```bash
# 1. Get kernel source
mkdir -p sources && cd sources
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.27.tar.xz
tar xf linux-6.12.27.tar.xz && cd ..

# 2. Get WiFi firmware
bash get_firmware.sh

# 3. Build wpa_supplicant (needs libnl-3-dev libssl-dev)
bash build_wpa.sh

# 4. Build kernel + ISO
bash build_nib.sh
```

Output: `nib-linux.iso`

## Write to USB

```bash
sudo dd if=nib-linux.iso of=/dev/sdX bs=4M status=progress
```

Disable **Secure Boot** in BIOS before booting.

## After Boot

```bash
wifi-connect --scan              # scan networks
wifi-connect MyNetwork pass123   # connect to WPA2
nib-install                      # install to disk
ns install <package>             # install package
```

## Architecture

```
GRUB → Linux 6.12 → initramfs → /init (shell) → /bin/sh
```

No systemd. No udev daemon. No package manager daemon.

## License

MIT
