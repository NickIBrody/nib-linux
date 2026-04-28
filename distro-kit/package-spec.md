# NIB Package Format

Archive extension:

- `.nib`

Compression:

- `tar.zst`

Archive contents:

```text
.nib/manifest.toml
root/usr/bin/...
root/usr/lib/...
root/etc/...
```

Manifest example:

```toml
name = "python"
version = "3.12.9"
release = 1
arch = "x86_64"
summary = "CPython interpreter"
deps = ["openssl", "zlib", "libffi", "sqlite", "readline", "ncurses"]
```

Repository layout:

```text
repo/
  index.json
  packages/
    python-3.12.9-1-x86_64.nib
    rustup-1.28.2-1-x86_64.nib
```

`index.json` contains:

- package name
- version
- release
- architecture
- summary
- dependency list
- archive relative path
- `sha256`
- uncompressed package size

Install model:

- packages extract into a target root such as `/`
- installed manifests are recorded in `var/lib/nib/db/*.json`
- package verification is based on the repository index hash

What this does not try to solve yet:

- transactional rollback
- delta updates
- signature verification
- dependency solver
- file ownership conflict resolution

Those are next-stage features once the format and bootstrap repo are stable.
