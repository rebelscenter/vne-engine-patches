#!/usr/bin/env bash
# Builds libbox as Libbox.xcframework for iOS (device + simulator) from the
# patched tree, with upstream's own build_libbox tool like the Android one.
# Output: out/apple/Libbox.xcframework (override with OUT=<dir>). Needs macOS + Xcode.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="$(tr -d ' \t\r\n' < "$ROOT/upstream.version")"
OUT="${OUT:-$ROOT/out/apple}"
SRC="$ROOT/out/sing-box"
export PATH="$PATH:$(go env GOPATH)/bin"
mkdir -p "$OUT"
# Tag from upstream.version plus patches/*.patch; fails if a patch does not apply.
bash "$ROOT/scripts/singbox-src.sh"
# Optional: VNE_LIBBOX_MARKER (patch 0002) is linked into libbox when set; empty otherwise.
cd "$SRC"
make lib_install
gomobile init
go run ./cmd/internal/build_libbox -target apple -platform ios,iossimulator
rm -rf "$OUT/Libbox.xcframework"
mv "$SRC/Libbox.xcframework" "$OUT/Libbox.xcframework"
ls "$OUT/Libbox.xcframework" | grep ios-arm64 >/dev/null
echo "built $OUT/Libbox.xcframework for $TAG ($(du -sh "$OUT/Libbox.xcframework" | cut -f1))"
