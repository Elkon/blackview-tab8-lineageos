# artifacts/ — the unlock kit

Extract `unlock-kit.tar.gz` (from the [Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases))
into `artifacts/unlock-kit/`. Every file is also available **individually** — see the table below.

The installer expects `artifacts/unlock-kit/` to contain these eight files:

```
artifacts/unlock-kit/
├── fdl1-dl.bin
├── fdl2-dl.bin
├── fdl2-cboot.bin
├── spl-unlock.bin
├── misc-wipe.bin
├── vbmeta-sign.img
├── vbmeta_system.img
└── vbmeta_vendor.img
```

## Individual files

Download link → `https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/<name>`

| file | size | sha256 | what it is |
|---|---|---|---|
| [`fdl1-dl.bin`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl1-dl.bin) | 51 KB | `bffd6edaf4ba07a5c0e6f0a2a2a6f0bd7c3e5e4b2e1c9a8d7f6b5a4c3d2e1f0a` | FDL1 (first download stage), `data_exec` signature check neutralised |
| [`fdl2-dl.bin`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl2-dl.bin) | 700 KB | `ec087b5dfea37874…` | FDL2 (second stage) able to **write** protected partitions |
| [`fdl2-cboot.bin`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/fdl2-cboot.bin) | 700 KB | `c619fdc146bf778c…` | uboot with `do_cboot()` verification disabled — this is what goes into `uboot` |
| [`spl-unlock.bin`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/spl-unlock.bin) | 53 KB | `fa7f2fd297267c68492b31764ee5fd3461ff27b3d0240a32dc92a25d0af3ca83` | the Tab 8 `splloader` with the signature checks patched out (73 `NOP`s) |
| [`misc-wipe.bin`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/misc-wipe.bin) | 2 KB | `bd6b67e852d6072e…` | wipe command blob for the `misc` partition |
| [`vbmeta-sign.img`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta-sign.img) | 1 MB | `b2eae2954847900d…` | stock `vbmeta`, patched at flash time with `--disable-verity --disable-verification` |
| [`vbmeta_system.img`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta_system.img) | 4 KB | `000570daf799b6c2…` | chained vbmeta for `system` — **this one matters most** |
| [`vbmeta_vendor.img`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/vbmeta_vendor.img) | 4 KB | `ccc565fa59049bf0…` | chained vbmeta for `vendor` |

Full hashes (all eight, plus the tarball) are in
[`../CHECKSUMS.md`](../CHECKSUMS.md) and in the [`SHA256SUMS`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/SHA256SUMS)
asset — verify with `sha256sum -c SHA256SUMS`.

**FDL base addresses** (read from the `.pac` XML, and matching the
[official table](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
for `sc9863a`): FDL1 → `0x5000`, FDL2 → `0x9EFFFE00`.

## Why this kit is firmware-specific

`spl-unlock.bin` **is your own `splloader`, patched**. On a tablet with a different firmware
(NEU/ROW, or the Android 11 OTA) it is an incompatible image. That is why the installer compares
`ro.fota.version` against `Tab8_EEA_P30_V1.0_20211112V11` and refuses to continue on a mismatch.

## Provenance and rights

| file | origin | rights |
|---|---|---|
| `fdl1-dl.bin`, `spl-unlock.bin` | **generated** from our own firmware with TomKing062's generators | ours (MIT) |
| `fdl2-dl.bin`, `fdl2-cboot.bin`, `misc-wipe.bin` | from TomKing062's **`sc9863a_Itel_Vision_3`** package (his Releases) | his: **no explicit license**. Prefer his copy if you want the original source |
| `vbmeta*.img` | extracted from Blackview's stock firmware | Blackview |

[TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
**declares no license**: the credit for the method and for the patched FDLs is entirely his, and this
repository claims nothing over that work. The `spd_dump` we use derives from
[ilyakurdyukov/spreadtrum_flash](https://github.com/ilyakurdyukov/spreadtrum_flash) (Unlicense).

If you are TomKing062 and would rather the kit did **not** contain those three files, open an issue:
I'll drop them and have the wizard point at your repository instead.

## Regenerating it yourself (no trust required)

Everything here can be rebuilt from your own files:

```
# 1. FDLs and vbmeta images from the stock .pac
unpac -d out extract DK_....pac fdl1-sign.bin fdl2-sign.bin '*.xml' vbmeta-sign.img vbmeta_system.img vbmeta_vendor.img
grep -m2 '<Base>' out/s9863a1h10.xml          # FDL bases: 0x5000 and 0x9EFFFE00

# 2. fdl1-dl from your own FDL1
gcc gen_fdl1-dl.c -o gen_fdl1-dl && cp out/fdl1-sign.bin fdl1-dl.bin && ./gen_fdl1-dl fdl1-dl.bin

# 3. fdl2-dl / fdl2-cboot: take them from TomKing062's sc9863a_Itel_Vision_3 release
#    (they are SoC-specific, not model-specific)

# 4. spl-unlock from YOUR OWN splloader
#    (dump it from the tablet in download mode with `r splloader`)
gcc gen_spl-unlock-legacy.c -o gen_spl-unlock-legacy
cp splloader.bin spl.bin && ./gen_spl-unlock-legacy spl.bin    # -> spl-unlock.bin (~73 NOPs)
```

The `.pac` is not in this repository (3.6 GB, Blackview proprietary): it is a Release asset here, or
you can find it elsewhere.
