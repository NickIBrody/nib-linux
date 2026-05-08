# Forge Linux

Forge Linux is a small custom Linux distribution project focused on a bootable live ISO, a shell-first recovery environment, and a simple installer for real hardware.

## What It Includes

- custom Linux `6.12` build flow
- live ISO booted with `GRUB`
- installer with `UEFI` and `BIOS` support
- live Wi-Fi helper commands
- experimental package tooling built around `ns`

## Repository Layout

```text
.
├── build_nib.sh
├── build_wpa.sh
├── configs/
├── distro-kit/
├── get_firmware.sh
├── rootfs/
├── screenshots/
└── tools/
```

Key paths:

- `rootfs/init`: init entrypoint for the live environment and installed system
- `rootfs/usr/local/bin/nib-install`: text installer
- `rootfs/usr/local/bin/wifi-connect`: live Wi-Fi helper
- `rootfs/bin/ns`: current shell package manager
- `distro-kit/ns-core`: Rust backend for package tooling
- `distro-kit/ns`: Ruby frontend and recipe workflow

## Boot Flow

The ISO boots into a minimal live system with:

- shell access on the console
- network helpers for wired and Wi-Fi setup
- `start-installer` for launching the installer
- `ns` for fetching packages in the live environment

Typical live commands:

```sh
wifi-connect --scan
wifi-connect <SSID> [password]
start-installer
ns install <package>
```

## Build Notes

The current build script assumes a local workspace like `/home/brody/nib-build` and expects:

- a built kernel image at the configured path
- prepared `rootfs_work`
- prepared `iso_root`
- host tools such as `cpio`, `gzip`, and `grub-mkrescue`

Main builder:

```sh
./build_nib.sh
```

Related helpers:

- `build_wpa.sh`: Wi-Fi userspace build helper
- `get_firmware.sh`: firmware fetch helper
- `tools/bootstrap_calamares_rootfs.sh`: bootstrap helper for a Calamares-based rootfs experiment

## Package Tooling

The current package manager is still `ns`. The distro branding changed to Forge Linux, but the package tooling name did not.

Current pieces:

- `rootfs/bin/ns`: lightweight shell package installer used in the live system
- `distro-kit/ns-core`: low-level package backend written in Rust
- `distro-kit/ns`: higher-level Ruby frontend for recipes and repository operations

This means distro renaming does not break package management unless the `ns` command, its paths, or its package repository are renamed too.

## Current State

- `UEFI` install flow is in better shape than legacy `BIOS`
- package tooling is functional but still experimental
- full `CPython` packaging is still in progress
- release ISOs are published as artifacts, not committed to git

## License

MIT
