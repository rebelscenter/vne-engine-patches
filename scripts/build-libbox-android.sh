#!/usr/bin/env bash
# Builds libbox as an Android AAR from the patched tree, using upstream's own
# build_libbox tool (its gomobile/tag set is what v1.14.0 needs).
# Output: out/android/libbox.aar (override with OUT=<dir>).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="$(tr -d ' \t\r\n' < "$ROOT/upstream.version")"
OUT="${OUT:-$ROOT/out/android}"
SRC="$ROOT/out/sing-box"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export JAVA_HOME="${JAVA_HOME:-$(brew --prefix openjdk@17 2>/dev/null)/libexec/openjdk.jdk/Contents/Home}"
export PATH="$PATH:$(go env GOPATH)/bin"
# Go >= 1.27.4 rejects cronet-go's `#cgo LDFLAGS: -l:libcronet.a`; allow exactly that flag
# (gomobile swallows the error, so the build just exits 1).
export CGO_LDFLAGS_ALLOW='-l:libcronet\.a'

mkdir -p "$OUT"
# Tag from upstream.version plus patches/*.patch; fails if a patch does not apply.
bash "$ROOT/scripts/singbox-src.sh"

# Optional: VNE_LIBBOX_MARKER (patch 0002) is linked into libbox when set; empty otherwise.

cd "$SRC"
# lib_install pins gomobile/gobind to the version this tag's build tool and
# tag set (badlinkname, tfogo_checklinkname0, ts_omit_*) actually link against.
make lib_install
gomobile init
go run ./cmd/internal/build_libbox -target android

cp "$SRC/libbox.aar" "$OUT/libbox.aar"

CLASSES_JAR="$(mktemp)"
trap 'rm -f "$CLASSES_JAR"' EXIT
unzip -p "$OUT/libbox.aar" classes.jar > "$CLASSES_JAR"
# Not grep -q: under pipefail its early exit SIGPIPEs the lister and fails a good build with 141.
jar tf "$CLASSES_JAR" | grep 'io/nekohasekai/libbox/Libbox.class' >/dev/null
unzip -l "$OUT/libbox.aar" | grep 'jni/arm64-v8a/libbox.so' >/dev/null

echo "built $OUT/libbox.aar for $TAG ($(du -h "$OUT/libbox.aar" | cut -f1))"
