#!/bin/bash
set -e

BUILDDIR=/home/brody/nib-build
ROOTFS=$BUILDDIR/rootfs_work
ISO_ROOT=$BUILDDIR/iso_root
KERNEL=$BUILDDIR/kernel/linux-6.12.27/arch/x86/boot/bzImage

echo "=== Checking kernel ==="
if [ ! -f "$KERNEL" ]; then
    echo "ERROR: kernel not built yet at $KERNEL"
    echo "Check: ps aux | grep make"
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
grub-mkrescue -o nib-linux.iso "$ISO_ROOT" \
    --modules="part_gpt part_msdos fat iso9660 linux normal chain all_video gfxterm" \
    2>&1 | grep -v "^$"

echo ""
echo "=== DONE ==="
echo "ISO: $(du -sh $BUILDDIR/nib-linux.iso | cut -f1)  →  $BUILDDIR/nib-linux.iso"
echo ""
echo "Записать на USB:"
echo "  sudo dd if=$BUILDDIR/nib-linux.iso of=/dev/sdX bs=4M status=progress"
