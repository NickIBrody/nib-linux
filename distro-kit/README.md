# NIB Distro Kit

This directory is the new foundation for turning `nib-build` into a real distro rather than a pile of shell glue.

Design goals:

- `Linux` kernel, not a greenfield kernel project
- `Rust` for low-level tooling and package mechanics
- `Ruby` for high-level package UX and recipe DSL
- reproducible local package repository
- bootstrap path for `Python`, `Rust`, `chawan`, and other developer tools

Current layout:

- `ns-core/`: Rust backend for packing, indexing, verifying, and installing packages
- `ns`: Ruby frontend that wraps the Rust backend and exposes package recipes
- `lib/nib/`: Ruby support code
- `recipes/`: bootstrap package recipes
- `examples/`: example package payloads and local repo
- `package-spec.md`: package archive and repository format

Suggested distro direction:

1. Keep the live ISO and installer simple.
2. Move package internals into `ns-core`.
3. Use `Ruby` for package recipes, dependency logic, repo commands, and user-facing CLI.
4. Bootstrap these packages first:
   - `zlib`
   - `openssl`
   - `ncurses`
   - `readline`
   - `sqlite`
   - `libffi`
   - `curl`
   - `pkg-config`
   - `python`
   - `rustup`
   - `chawan`

Build the backend:

```bash
cd /home/brody/nib-build/distro-kit/ns-core
cargo build --release
```

Use the frontend:

```bash
cd /home/brody/nib-build/distro-kit
./ns recipe list
./ns repo index examples/repo
./ns repo list examples/repo
./ns install hello --repo examples/repo --root /tmp/nib-root
```
