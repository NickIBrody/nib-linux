version "0.29.2"
summary "Metadata lookup for building native software"
homepage "https://www.freedesktop.org/wiki/Software/pkg-config/"
build_dep "gcc", "make"
runtime_dep
step "build pkgconf-compatible interface"
step "install binary and pkg.m4 support files"
step "use as a base dependency for Python and chawan builds"
