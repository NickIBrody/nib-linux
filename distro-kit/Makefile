NS_CORE := /home/brody/nib-build/distro-kit/ns-core/target/release/ns-core

.PHONY: build smoke

build:
	cd /home/brody/nib-build/distro-kit/ns-core && cargo build --release

smoke: build
	rm -rf /tmp/nib-smoke-root /tmp/nib-smoke-repo
	mkdir -p /tmp/nib-smoke-repo/packages
	$(NS_CORE) pack \
		--name hello \
		--version 0.1.0 \
		--release 1 \
		--arch x86_64 \
		--summary "Example hello package" \
		--source /home/brody/nib-build/distro-kit/examples/hello/root \
		--output /tmp/nib-smoke-repo/packages/hello-0.1.0-1-x86_64.nib
	$(NS_CORE) index --repo-dir /tmp/nib-smoke-repo
	/home/brody/nib-build/distro-kit/ns repo list /tmp/nib-smoke-repo
	/home/brody/nib-build/distro-kit/ns install hello --repo /tmp/nib-smoke-repo --root /tmp/nib-smoke-root
	test -f /tmp/nib-smoke-root/usr/bin/hello
