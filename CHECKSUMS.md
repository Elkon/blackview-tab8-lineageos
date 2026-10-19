# What you download, and its fingerprint

Always verify with `sha256sum <file>`. The installer checks the GSI by itself. **No hash below is
typed by hand**: they are generated from the real files when the release is made.

## GSI — LineageOS 20 (Andy Yan)

| | |
|---|---|
| file | `lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img` (2.2 GB, uncompressed) |
| sha256 | `3b5ad7fc32bc59321a936f001d427602bc6942dbe4338238618f8d916375ef6e` |
| source | <https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/> |

Gunzip the `.img.gz` **before** computing the sha256: the value above is for the unpacked image.

## Stock firmware — for recovery

| | |
|---|---|
| Release asset | [`DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz) (1.9 GB) |
| sha256 of the `.gz` | `0f7dd60dd51f22f0c4e7099393d698676d703327fe3f3eb6ac676ca61524b362` |
| sha256 of the unpacked `.pac` | `e0531f310597b4bd4ee0bad232640a4eecfc2c11a2776d27ee955df3c6d30d8c` |
| board declared by the archive | `s9863a1h10` — the same as this tablet |

Obtained with `gunzip DK_....pac.gz` (3.6 GB unpacked). It is a **mirror** of Blackview firmware that
is already publicly distributed: if you are the rights holder and want it removed, open an issue.

## Unlock kit

| | |
|---|---|
| file | [`unlock-kit.tar.gz`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/unlock-kit.tar.gz) (716 KB) |
| sha256 | `811d28d52306fc843cad28a19ad7b0060d2cce9e25072996a972cf7599906fb9` |

The tarball contains its own `SHA256SUMS`, so it verifies itself: `sha256sum -c SHA256SUMS` after
extracting.

Every file is also downloadable **on its own**:

| file | sha256 | link |
|---|---|---|
| `fdl1-dl.bin` | `bffd6edaf4ba07a57bc0db7ee96046bd772113de09ca308caf5537d660ddfbc5` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl1-dl.bin) |
| `fdl2-cboot.bin` | `c619fdc146bf778c1a3d92475f88c87f95f1b2ecee4efaa2577fe06bfe3c5dcd` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl2-cboot.bin) |
| `fdl2-dl.bin` | `ec087b5dfea37874cd81d5edbc689739f60299841f6fb5622065555dcbebf294` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl2-dl.bin) |
| `misc-wipe.bin` | `bd6b67e852d6072e6fb87040f2ac40216d5b661b7fa661e7024569ecf8ddb3a7` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/misc-wipe.bin) |
| `spl-unlock.bin` | `fa7f2fd297267c68492b31764ee5fd3461ff27b3d0240a32dc92a25d0af3ca83` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/spl-unlock.bin) |
| `vbmeta-sign.img` | `b2eae2954847900dcc268b58f3348e45adb1656c255347448181431ec24876cc` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta-sign.img) |
| `vbmeta_system.img` | `000570daf799b6c25d185e2940a3d7531f953822fe949f71d99a898a24076993` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta_system.img) |
| `vbmeta_vendor.img` | `ccc565fa59049bf0df790162fc960451b935b11302f4971923b16e351eb6e947` | [download](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta_vendor.img) |

## The rule

**Do not want to trust our binaries?** Rebuild them from your own files: the procedure is in
[`artifacts/README.md`](artifacts/README.md). You do not have to trust anyone.
