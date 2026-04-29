# Forge Linux

Forge Linux is a custom Linux distribution project built around a small live ISO, a shell-driven initramfs environment, and a simple disk installer for real hardware.

Current state:

- custom Linux 6.12 kernel flow
- live ISO with `GRUB`
- installer with `UEFI + BIOS` target layout support
- Wi-Fi helper commands in the live system
- experimental package tooling:
  - `ns` shell package fetcher
  - `distro-kit/ns-core` Rust backend
  - `distro-kit/ns` Ruby frontend and recipe DSL

## Repository Layout

```text
.
├── build_nib.sh
├── configs/
├── distro-kit/
├── get_firmware.sh
├── build_wpa.sh
├── rootfs/
└── screenshots/
```

Important paths:

- `rootfs/init`: live and installed init entrypoint
- `rootfs/usr/local/bin/nib-install`: TUI installer
- `rootfs/usr/local/bin/wifi-connect`: Wi-Fi helper
- `rootfs/bin/ns`: simple package fetch tool
- `distro-kit/`: next-generation package system work

## Features

- boots from ISO via `GRUB`
- live shell environment
- disk installer with:
  - target disk selection
  - adaptive `EFI` sizing for smaller disks
  - `UEFI` removable boot install
  - `Legacy BIOS` install path
- Wi-Fi helper commands
- package system experiments in `Rust` and `Ruby`

## Build Notes

The current builder expects a local workspace like `/home/brody/nib-build` with:

- kernel source and built `bzImage`
- prepared `rootfs_work`
- `iso_root`
- required userspace tools available on the host

This repo tracks the project source and scripts. The published ISO is attached to GitHub Releases rather than committed to git.

## Live Commands

After boot:

```sh
wifi-connect --scan
wifi-connect <SSID> [password]
nib-install
ns install <package>
```

## Package Work

`distro-kit/` is the new packaging direction:

- low-level backend in `Rust`
- high-level CLI and recipes in `Ruby`
- bootstrap recipes for:
  - `python`
  - `rustup`
  - `rust`
  - `chawan`
  - `openssl`
  - `zlib`
  - `sqlite`
  - `readline`
  - `ncurses`
  - `libffi`

## Release Artifact

Latest ISO built in this update:

- `nib-linux.iso`
- size: about `253 MB`

## Caveats

- `python3` is not yet included in the live rootfs by default
- `micropython` exists in the package repo, but full CPython packaging is still in progress
- `UEFI` install path is in better shape than `Legacy BIOS`

## License

MIT
