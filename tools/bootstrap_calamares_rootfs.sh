#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="${1:-$ROOT/rootfs_work}"
PKG_LIST_FILE="${PKG_LIST_FILE:-$ROOT/tools/calamares-packages.txt}"
WORKDIR="${WORKDIR:-$ROOT/.calamares-bootstrap}"

if [[ ! -d "$ROOTFS" ]]; then
    echo "rootfs not found: $ROOTFS" >&2
    exit 1
fi

if [[ ! -f "$PKG_LIST_FILE" ]]; then
    echo "package list not found: $PKG_LIST_FILE" >&2
    exit 1
fi

command -v apt >/dev/null 2>&1 || { echo "apt is required" >&2; exit 1; }
command -v apt-cache >/dev/null 2>&1 || { echo "apt-cache is required" >&2; exit 1; }
command -v dpkg-deb >/dev/null 2>&1 || { echo "dpkg-deb is required" >&2; exit 1; }

mkdir -p "$WORKDIR/downloads"
mapfile -t seed_packages < <(grep -Ev '^\s*(#|$)' "$PKG_LIST_FILE")

printf '%s\n' "${seed_packages[@]}" > "$WORKDIR/resolved-packages.txt"

apt-cache depends \
    --recurse \
    --no-recommends \
    --no-suggests \
    --no-conflicts \
    --no-breaks \
    --no-replaces \
    --no-enhances \
    "${seed_packages[@]}" 2>/dev/null \
    | awk '
        /Depends:|PreDepends:/ { print $2 }
    ' \
    | sed 's/:amd64$//; s/:any$//' \
    | grep -v ':i386$' \
    | grep -v '^<' \
    >> "$WORKDIR/resolved-packages.txt"

sort -u -o "$WORKDIR/resolved-packages.txt" "$WORKDIR/resolved-packages.txt"

printf 'Resolved %d packages\n' "$(wc -l < "$WORKDIR/resolved-packages.txt")"

pushd "$WORKDIR/downloads" >/dev/null
while IFS= read -r pkg; do
    echo "Downloading $pkg"
    apt download "$pkg" >/dev/null
done < "$WORKDIR/resolved-packages.txt"
popd >/dev/null

while IFS= read -r deb; do
    echo "Extracting $(basename "$deb")"
    dpkg-deb -x "$deb" "$ROOTFS"
done < <(find "$WORKDIR/downloads" -maxdepth 1 -name '*.deb' | sort)

chmod +x "$ROOTFS/usr/local/bin/start-installer" "$ROOTFS/usr/local/bin/start-live-gui"

cat <<EOF

Calamares bootstrap finished.

Next steps:
  1. Rebuild the ISO:
       bash $ROOT/build_iso.sh
  2. Boot the live image and run:
       start-installer
  3. If Calamares starts, keep nib-install only as an emergency fallback.

Artifacts:
  Package list: $PKG_LIST_FILE
  Resolved set: $WORKDIR/resolved-packages.txt
  Deb cache:     $WORKDIR/downloads
EOF
