# artifacts/

Download [`unlock-kit.tar.gz`](https://github.com/Elkon/blackview-tab8-lineageos/releases/download/v1.0.0/unlock-kit.tar.gz)
(716 KB) from the [Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases) and extract it
here, so that the installer finds the files in `artifacts/unlock-kit/`.

    tar xzf unlock-kit.tar.gz -C artifacts/unlock-kit/
    cd artifacts/unlock-kit && sha256sum -c SHA256SUMS

## What is in it

Eight files, and the installer needs all of them.

`fdl1-dl.bin` is FDL1, the first download stage, with the `data_exec` signature check neutralised.
It loads at `0x5000`.

`fdl2-dl.bin` is FDL2, the second stage, and it is the one that can write protected partitions. It
loads at `0x9EFFFE00`.

`fdl2-cboot.bin` is an uboot with `do_cboot()` verification off. This is what gets written into the
`uboot` partition.

`spl-unlock.bin` is the Tab 8 `splloader` with the signature checks replaced by 73 `NOP`s.

`misc-wipe.bin` is a wipe command blob for the `misc` partition, 2 KB.

`vbmeta-sign.img`, `vbmeta_system.img` and `vbmeta_vendor.img` are the three stock vbmeta images, to
be patched with `--disable-verity --disable-verification` at flash time. The `system` one is the one
that matters; the other two keep the chain consistent.

Both FDL bases were read from the `.xml` inside the `.pac`, and they match the table in
[TomKing062's wiki](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
for `sc9863a`.

## One firmware only

`spl-unlock.bin` is your own splloader, patched. On a tablet with a different firmware, NEU or ROW or
the Android 11 OTA, it is the wrong image. The installer compares `ro.fota.version` with
`Tab8_EEA_P30_V1.0_20211112V11` and refuses to continue otherwise.

## Where the files come from

`fdl1-dl.bin` and `spl-unlock.bin` were generated from our own firmware with TomKing062's generators.

`fdl2-dl.bin`, `fdl2-cboot.bin` and `misc-wipe.bin` come from TomKing062's `sc9863a_Itel_Vision_3`
package. His project declares no license, so those files are his; if you would rather have the
originals, take them from his release.

The `vbmeta` images come from Blackview's stock firmware.

If you are TomKing062 and would prefer the kit did not carry those three files, open an issue.

## Rebuilding it yourself

No trust required, everything can be produced from your own files.

Get the FDLs and the vbmeta images out of the `.pac` with `unpac`, which ships with
`spreadtrum_flash`:

    unpac -d out extract DK_....pac fdl1-sign.bin fdl2-sign.bin '*.xml' vbmeta-sign.img vbmeta_system.img vbmeta_vendor.img
    grep -m2 '<Base>' out/s9863a1h10.xml

Generate the FDL1 variant:

    gcc gen_fdl1-dl.c -o gen_fdl1-dl && cp out/fdl1-sign.bin fdl1-dl.bin && ./gen_fdl1-dl fdl1-dl.bin

`fdl2-dl.bin` and `fdl2-cboot.bin` are specific to the SoC rather than the model. Take them from
TomKing062's `sc9863a_Itel_Vision_3` release.

Generate the unlock SPL from your own splloader, the one you dumped from the tablet in download mode
with `r splloader`:

    gcc gen_spl-unlock-legacy.c -o gen_spl-unlock-legacy
    cp splloader.bin spl.bin && ./gen_spl-unlock-legacy spl.bin

That writes `spl-unlock.bin` and nops about 73 instructions. If it finds nothing to patch, the binary
is not the one the generator expects and you should stop rather than flash it.
