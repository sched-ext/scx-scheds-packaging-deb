# scx-deb

Debian/Ubuntu packaging for [sched-ext/scx](https://github.com/sched-ext/scx),
the collection of sched_ext schedulers and tools.

This repository contains **packaging material only**. It does not carry any
upstream source code: the `scx` sources are fetched from the upstream Git
repository at build time and combined with the `debian/` directory shipped
here to produce a buildable Debian source tree.

## Layout

- `debian/` - Debian packaging files (`control`, `changelog`, `rules`,
  `copyright`, `patches/`, `watch`, systemd unit, install manifest, etc.).
- `build.sh` - Helper script that produces an `orig` tarball from upstream
  and overlays `debian/` on top to yield a ready-to-build source package.
- `debian/sanitize-vendor-checksums.py` - Fixes up `vendor/*/.cargo-checksum.json`
  after stripping prebuilt Windows binaries from vendored Rust crates.

## Building a source package

Requirements: `git`, `cargo`, `python3`, `dpkg-dev`, and the build
dependencies listed in `debian/control`.

```sh
./build.sh
cd scx-<version>
dpkg-buildpackage -S -us -uc -d
```

`build.sh`:

1. Reads the upstream version from `debian/changelog`.
2. Clones `sched-ext/scx` at the matching `v<version>` tag.
3. Vendors Rust crates, strips prebuilt Windows binaries, and sanitizes
   the vendor checksums.
4. Creates `scx_<version>.orig.tar.gz` (without `debian/` inside).
5. Overlays this branch's `debian/` directory to produce the source tree.

## Upstream

- Project: <https://github.com/sched-ext/scx>
- Upstream releases are tracked via `debian/watch`.

## Maintainer

Andrea Righi &lt;arighi@nvidia.com&gt;
