#!/bin/bash
#
# Build a Debian source package by:
#   1. Cloning upstream sched-ext/scx at the tag matching debian/changelog.
#   2. Vendoring Rust crates and stripping prebuilt Windows binaries.
#   3. Packing the result as scx_<version>.orig.tar.gz (no debian/ inside).
#   4. Overlaying this branch's debian/ directory on top to produce a
#      ready-to-build source tree under ./scx-<version>/.
#
# Run from the root of the packaging-only branch (where debian/ lives).

set -e

UPSTREAM_URL="https://github.com/sched-ext/scx"

if [[ ! -d debian ]]; then
    echo "ERROR: run from the packaging branch root (debian/ not found)"
    exit 1
fi

PKG_ROOT="$(pwd)"

# Upstream version = changelog version minus the Debian revision and any
# repack suffix (e.g. 1.1.1+ds-1 -> 1.1.1).
version=$(dpkg-parsechangelog -l debian/changelog -SVersion)
upstream_version="${version%-*}"
upstream_tag="v${upstream_version%%+*}"

orig_dir="scx-${upstream_version}"
orig_tarball="scx_${upstream_version}.orig.tar.gz"

# Idempotent: clean any leftovers from a previous run.
rm -rf "$orig_dir" "$orig_tarball"

# 1. Clone upstream at the matching tag.
echo "Cloning ${UPSTREAM_URL} at ${upstream_tag}..."
git clone --depth 1 --branch "$upstream_tag" "$UPSTREAM_URL" "$orig_dir"
rm -rf "$orig_dir/.git"

# 2. Vendor Rust crates, strip prebuilt Windows binaries, sanitize checksums.
(
    cd "$orig_dir"
    cargo vendor
    find vendor \( -iname '*.dll' -o -iname '*.exe' \) -delete
    python3 "$PKG_ROOT/debian/sanitize-vendor-checksums.py"
)

# 3. Create the orig tarball (no debian/ inside).
echo "Creating orig tarball..."
tar --create --gzip \
    --owner=0 --group=0 --numeric-owner \
    --file "$orig_tarball" \
    "$orig_dir"

# 4. Overlay debian/ to produce the source build tree.
cp -r debian "$orig_dir/"

echo "Done."
ls -ltrah "$orig_tarball"
echo
echo "Next: cd $orig_dir && dpkg-buildpackage -S -us -uc -d"
