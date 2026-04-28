#!/bin/bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")" && pwd)
BUILDDIR=${BUILDDIR:-"$REPO_ROOT"}
ROOTFS=${ROOTFS:-"$BUILDDIR/rootfs_work"}
ISO_ROOT=${ISO_ROOT:-"$BUILDDIR/iso_root"}
KERNEL=${KERNEL:-"$BUILDDIR/kernel/linux-6.12.27/arch/x86/boot/bzImage"}
ISO_NAME=${ISO_NAME:-nib-linux.iso}

echo "=== Checking kernel ==="
if [ ! -f "$KERNEL" ]; then
    echo "ERROR: kernel not built yet at $KERNEL"
    echo "Set KERNEL=/path/to/bzImage or build the kernel first."
    exit 1
fi
echo "Kernel: $(du -sh $KERNEL | cut -f1)"

echo "=== Packing initramfs ==="
chmod +x "$ROOTFS/init"
chmod +x "$ROOTFS/usr/local/bin/"* 2>/dev/null || true
chmod +x "$ROOTFS/usr/local/sbin/"* 2>/dev/null || true

mkdir -p "$ISO_ROOT/boot/grub"
cd "$ROOTFS"
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$ISO_ROOT/boot/initrd.img"
echo "initrd: $(du -sh $ISO_ROOT/boot/initrd.img | cut -f1)"

echo "=== Creating rootfs archive for installer ==="
tar -czf "$ISO_ROOT/boot/rootfs.tar.gz" -C "$ROOTFS" .
echo "rootfs.tar.gz: $(du -sh $ISO_ROOT/boot/rootfs.tar.gz | cut -f1)"

echo "=== Copying kernel ==="
cp "$KERNEL" "$ISO_ROOT/boot/vmlinuz"
echo "vmlinuz: $(du -sh $ISO_ROOT/boot/vmlinuz | cut -f1)"

echo "=== Building ISO ==="
cd "$BUILDDIR"
grub-mkrescue -o "$ISO_NAME" "$ISO_ROOT" \
    --modules="part_gpt part_msdos fat iso9660 linux normal chain" \
    2>&1 | grep -v "^$"

echo ""
echo "=== DONE ==="
echo "ISO: $(du -sh "$BUILDDIR/$ISO_NAME" | cut -f1)  →  $BUILDDIR/$ISO_NAME"
echo ""
echo "Write to USB:"
echo "  sudo dd if=$BUILDDIR/$ISO_NAME of=/dev/sdX bs=4M status=progress"
