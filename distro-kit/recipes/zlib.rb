version "1.3.1"
summary "Compression library required by Python, tar, and package archives"
homepage "https://zlib.net/"
build_dep "gcc", "make"
runtime_dep
step "build shared and static libraries"
step "install headers, libz, and pkg-config metadata"
step "use as a hard bootstrap dependency"
