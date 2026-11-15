# VNE engine patches

Source code of the modified network engine used by the VNE app
(https://vne.world). The engine is the third-party open-source project
[sing-box](https://github.com/SagerNet/sing-box) by nekohasekai, version
**v1.14.0** (pinned in `upstream.version`), with the patches in `patches/`
applied. This repository is published to meet the source-code obligations of
the GNU GPL v3.

This is **not** the official sing-box project and is not affiliated with or
endorsed by it. For the engine itself, use the upstream repository.

## Patches

| Patch | What it changes |
|---|---|
| `0001-reality-keep-chrome-mlkem.patch` | REALITY client keeps the X25519MLKEM768 key share for the Chrome uTLS fingerprint (required by Xray ≥ 26.9.8 REALITY servers); other fingerprints are filtered as before. |
| `0002-libbox-vne-engine-marker.patch` | libbox: optional build marker string, set at link time from `VNE_LIBBOX_MARKER` and readable via `VNEEngineMarker()`; empty if not set. |
| `0003-libbox-oomprofile-go127-record.patch` | libbox OOM profiler: memory-profile record layout for Go 1.27 (keeps the old layout for earlier Go). |
| `0004-xhttp-client-transport.patch` | New `xhttp` V2Ray transport: client for Xray-core's XHTTP ("splithttp") in stream-one and stream-up modes over HTTP/2, with tests. |
| `0005-deps-security-bumps.patch` | Dependency updates: Go 1.26, `golang.org/x/*`, gRPC and several indirect modules. |

`patches/SHA256SUMS` lists the digest of every patch; the scripts refuse a
patch whose digest does not match.

## Build

Requirements: git, Go (1.26+), make. Android: Android SDK + NDK and JDK 17.
iOS: macOS with Xcode.

```sh
# Clone upstream v1.14.0 into out/sing-box, verify and apply all patches,
# run the XHTTP transport tests.
bash scripts/singbox-src.sh

# Android: out/android/libbox.aar
bash scripts/build-libbox-android.sh

# iOS (device + simulator): out/apple/Libbox.xcframework
bash scripts/build-libbox-apple.sh
```

Both build scripts call `singbox-src.sh` first, then upstream's own
`cmd/internal/build_libbox` tool. `OUT=<dir>` overrides the output directory;
`ANDROID_HOME` and `JAVA_HOME` are honoured if set. `VNE_SINGBOX_PATCHES=none`
prepares the pristine upstream tree without patches.

To apply the patches by hand:

```sh
git clone --depth 1 --branch v1.14.0 https://github.com/SagerNet/sing-box
cd sing-box
for p in ../patches/*.patch; do git apply "$p"; done
```

## License

GNU General Public License v3.0 or later — full text in `LICENSE`. The upstream
copyright notice and its additional term ("no derivative work may use the name
or imply association with this application without prior consent") are
reproduced in `NOTICE`.

---

## Кратко по-русски

Исходники изменённого сетевого движка приложения VNE: upstream-проект
[sing-box](https://github.com/SagerNet/sing-box) v1.14.0 и наши патчи из
`patches/` (список выше). Это не официальный sing-box и не связан с ним.
Сборка: `bash scripts/singbox-src.sh` — скачать upstream и наложить патчи;
затем `scripts/build-libbox-android.sh` (AAR) или `scripts/build-libbox-apple.sh`
(XCFramework для iOS). Лицензия — GNU GPL v3 или новее (`LICENSE`), уведомление
upstream и дополнительное условие — в `NOTICE`.
