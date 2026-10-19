# artifacts/ — the unlock kit

Download **[`unlock-kit.tar.gz`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/unlock-kit.tar.gz)**
(716 KB) from the [Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases) and extract it
into `artifacts/unlock-kit/`.

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

## What is inside

| file | size | what it is |
|---|---|---|
| `fdl1-dl.bin` | 51 KB | FDL1 (first download stage), `data_exec` signature check neutralised |
| `fdl2-dl.bin` | 700 KB | FDL2 (second stage) able to **write** protected partitions |
| `fdl2-cboot.bin` | 700 KB | uboot with `do_cboot()` verification disabled — this is what goes into `uboot` |
| `spl-unlock.bin` | 53 KB | the Tab 8 `splloader` with the signature checks patched out (73 `NOP`s) |
| `misc-wipe.bin` | 2 KB | wipe command blob for the `misc` partition |
| `vbmeta-sign.img` | 1 MB | stock `vbmeta`, patched at flash time with `--disable-verity --disable-verification` |
| `vbmeta_system.img` | 4 KB | chained vbmeta for `system` — **this one matters most** |
| `vbmeta_vendor.img` | 4 KB | chained vbmeta for `vendor` |

The exact hashes of all eight (and of the tarball) are in [`../CHECKSUMS.md`](../CHECKSUMS.md); the
tarball also carries its own `SHA256SUMS`, so it verifies itself:

```
tar xzf unlock-kit.tar.gz -C artifacts/unlock-kit/
cd artifacts/unlock-kit && sha256sum -c SHA256SUMS
```

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
