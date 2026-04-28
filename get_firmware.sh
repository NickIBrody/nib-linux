#!/bin/bash
set -e

FIRMWARE_DIR="rootfs/lib/firmware"
LINUX_FIRMWARE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
TMP_FW="/tmp/linux-firmware-sparse"

echo "--- Downloading WiFi firmware ---"
mkdir -p "$FIRMWARE_DIR"

if ! command -v git &>/dev/null; then
    echo "git required"
    exit 1
fi

rm -rf "$TMP_FW"
git clone --depth=1 --filter=blob:none --sparse "$LINUX_FIRMWARE_URL" "$TMP_FW"
cd "$TMP_FW"
git sparse-checkout set \
    iwlwifi \
    ath10k \
    ath11k \
    ath3k.fw \
    brcm \
    rtlwifi \
    rtl_nic \
    rtl8192e \
    rt2870.bin \
    mt7601u.bin \
    regulatory.db \
    regulatory.db.p7s

cd - > /dev/null

echo "--- Copying firmware to $FIRMWARE_DIR ---"
cp -r "$TMP_FW"/iwlwifi*       "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/iwlwifi        "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/ath10k         "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/ath11k         "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/brcm           "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/rtlwifi        "$FIRMWARE_DIR/" 2>/dev/null || true
cp -r "$TMP_FW"/rtl_nic        "$FIRMWARE_DIR/" 2>/dev/null || true
cp "$TMP_FW"/regulatory.db     "$FIRMWARE_DIR/" 2>/dev/null || true
cp "$TMP_FW"/regulatory.db.p7s "$FIRMWARE_DIR/" 2>/dev/null || true
cp "$TMP_FW"/rt2870.bin        "$FIRMWARE_DIR/" 2>/dev/null || true
cp "$TMP_FW"/mt7601u.bin       "$FIRMWARE_DIR/" 2>/dev/null || true

echo "--- Done: firmware in $FIRMWARE_DIR ---"
ls "$FIRMWARE_DIR"
