#!/usr/bin/env bash
# Prepares out/sing-box: the upstream SagerNet/sing-box tree at the tag pinned in
# upstream.version with every patches/*.patch applied. The Android and Apple
# library builds start from this script. A patch that no longer applies, or
# whose digest drifted from patches/SHA256SUMS, fails the build out loud.
#
#   bash scripts/singbox-src.sh            # prepare the patched tree
#   VNE_SINGBOX_PATCHES=none bash ...      # pristine upstream (control builds only)
set -euo pipefail
# Patches apply in glob order; pin it so every host sorts the same way.
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="$(tr -d ' \t\r\n' < "$ROOT/upstream.version")"
SRC="$ROOT/out/sing-box"
PATCHES="$ROOT/patches"

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

mkdir -p "$ROOT/out"
if [ ! -d "$SRC/.git" ]; then
  # autocrlf=false: a patch made on macOS must apply byte-for-byte on Windows.
  git -c core.autocrlf=false clone --depth 1 --branch "$TAG" https://github.com/SagerNet/sing-box "$SRC"
fi
git -C "$SRC" config core.autocrlf false
git -C "$SRC" fetch --depth 1 origin "refs/tags/$TAG:refs/tags/$TAG"
# A previous run left the tree patched; start every build from the pristine tag.
git -C "$SRC" reset -q --hard "$TAG"
# A patch may add files; reset keeps untracked ones, so a second apply would fail.
git -C "$SRC" clean -fdq

if [ "${VNE_SINGBOX_PATCHES:-}" = "none" ]; then
  echo "singbox-src: $TAG without patches (VNE_SINGBOX_PATCHES=none)"
  exit 0
fi

for patch in "$PATCHES"/*.patch; do
  [ -e "$patch" ] || { echo "singbox-src: no patches in $PATCHES" >&2; exit 1; }
  name="$(basename "$patch")"
  want="$(grep -E "^[0-9a-f]{64}  $name\$" "$PATCHES/SHA256SUMS" | cut -d' ' -f1 || true)"
  have="$(sha256_of "$patch")"
  if [ -z "$want" ] || [ "$want" != "$have" ]; then
    echo "singbox-src: $name does not match patches/SHA256SUMS (have $have)" >&2
    exit 1
  fi
  if ! git -C "$SRC" apply --check "$patch"; then
    echo "singbox-src: $name does not apply to $TAG; rebase the patch" >&2
    exit 1
  fi
  git -C "$SRC" apply "$patch"
  echo "singbox-src: applied $name ($have)"
done
# Patch 0004 adds the XHTTP transport; its tests gate every build (host GOOS/GOARCH).
(cd "$SRC" && env -u GOOS -u GOARCH CGO_ENABLED=0 go test -count=1 ./transport/v2rayxhttp/)
echo "singbox-src: $TAG + $(ls "$PATCHES"/*.patch | wc -l | tr -d ' ') patch(es) in $SRC"
