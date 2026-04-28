#!/bin/bash
set -e

WPA_VERSION="2.11"
WPA_URL="https://w1.fi/releases/wpa_supplicant-${WPA_VERSION}.tar.gz"
BUILD_DIR="/tmp/wpa_build"

echo "--- Building wpa_supplicant $WPA_VERSION statically ---"

if ! command -v gcc &>/dev/null; then
    echo "gcc required"
    exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -f "wpa_supplicant-${WPA_VERSION}.tar.gz" ]; then
    wget -q "$WPA_URL" || curl -L -o "wpa_supplicant-${WPA_VERSION}.tar.gz" "$WPA_URL"
fi

tar xzf "wpa_supplicant-${WPA_VERSION}.tar.gz"
cd "wpa_supplicant-${WPA_VERSION}/wpa_supplicant"

cat > .config << 'EOF'
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL32=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_TLS=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TTLS=y
CONFIG_EAP_PSK=y
CONFIG_EAP_FAST=y
CONFIG_EAP_PAX=y
CONFIG_EAP_SAKE=y
CONFIG_EAP_GPSK=y
CONFIG_WPS=y
CONFIG_PKCS12=y
CONFIG_SMARTCARD=y
CONFIG_CTRL_IFACE=y
CONFIG_CTRL_IFACE_UNIX=y
CONFIG_BACKEND=file
CONFIG_IBSS_RSN=y
CONFIG_WPA_CLI_EDIT=y
CONFIG_P2P=y
CONFIG_SAE=y
CONFIG_OWE=y
CONFIG_DPP=y
CFLAGS += -static
LDFLAGS += -static
EOF

make -j$(nproc)

DEST="$(pwd)/../../../../rootfs/usr/local/bin"
mkdir -p "$DEST"

cp wpa_supplicant "$DEST/wpa_supplicant"
cp wpa_passphrase "$DEST/wpa_passphrase"
cp wpa_cli "$DEST/wpa_cli" 2>/dev/null || true

echo "--- wpa_supplicant installed to rootfs ---"
