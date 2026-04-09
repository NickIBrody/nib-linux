#!/bin/bash

# Пути
PROJECT_DIR=$(pwd)
ROOTFS=$PROJECT_DIR/rootfs
ISO_ROOT=$PROJECT_DIR/iso_root

echo "--- Step 1: Packing initramfs ---"
cd $ROOTFS
find . -print0 | cpio --null -ov --format=newc | gzip -9 > $PROJECT_DIR/initramfs.cpio.gz

echo "--- Step 2: Preparing ISO structure ---"
cd $PROJECT_DIR
mkdir -p iso_root/boot/grub
cp initramfs.cpio.gz iso_root/boot/initrd.img
# Ядро у нас уже должно быть собрано в sources
cp sources/linux-6.8/arch/x86/boot/bzImage iso_root/boot/vmlinuz

echo "--- Step 3: Creating GRUB config ---"
cat <<EOT > iso_root/boot/grub/grub.cfg
set default=0
set timeout=2

menuentry "NIB Linux (Monster Edition)" {
    linux /boot/vmlinuz quiet console=tty0
    initrd /boot/initrd.img
}
EOT

echo "--- Step 4: Generating ISO image ---"
grub-mkrescue -o nib-linux.iso iso_root

echo "--- Done! Burn or boot nib-linux.iso ---"
