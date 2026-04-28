version "3.4.7"
summary "Foreign function interface runtime for Python and tooling"
homepage "https://github.com/libffi/libffi"
build_dep "gcc", "make"
runtime_dep
step "configure for x86_64-linux-gnu"
step "install shared library and headers"
step "expose pkg-config metadata"
