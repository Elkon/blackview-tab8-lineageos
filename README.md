# LineageOS 20 on the Blackview Tab 8 (Unisoc SC9863A)

LineageOS 20 (Android 13) runs on the Blackview Tab 8, a 2020 Unisoc SC9863A tablet that the vendor
abandoned and for which no kernel source or device tree exists.

Tested on one device. Wifi, touch, audio, auto-rotation and brightness work. Camera and the LTE modem
were never tried.

## What has to happen

The bootloader cannot be unlocked from fastboot: `fastboot flashing unlock` answers `Not implemet.`
It is unlocked through the BootROM instead, with CVE-2022-38694, the exploit published by TomKing062.
After that a LineageOS GSI replaces the stock `system` and AVB gets switched off.

Read [docs/00-risks.md](docs/00-risks.md) first. The procedure wipes the tablet and writes to
bootloader partitions, and recovery depends on having the stock firmware at hand.

## Requirements

Linux on x86_64. Not Windows: the SPRD and libusb drivers fight each other there.

A tablet running `Tab8_EEA_P30_V1.0_20211112V11`. The installer reads `ro.fota.version` and refuses
anything else, because the unlock files are built from that firmware.

A USB cable that carries data. About 5 GB of free disk.

## Install

    git clone https://github.com/Elkon/blackview-tab8-lineageos.git
    cd blackview-tab8-lineageos
    ./install.sh check
    ./install.sh unlock
    ./install.sh flash

`unlock` and `flash` stop and ask before every write, and both need you to put the tablet in download
mode by hand. `--dry-run` prints the commands without running them.

## Files

    install.sh              check | unlock | flash | wipe | verify | restore
    artifacts/              unlock kit, what each file is, how to rebuild it
    docs/00-risks.md        what breaks and what is hard to undo
    docs/01-preparation.md  tools, udev rules, downloads
    docs/02-unlock.md       the BootROM procedure
    docs/03-flash-gsi.md    fastbootd, dynamic partitions, vbmeta, wipe
    docs/04-post-install.md hardware check, tuning, battery
    docs/05-recovery.md     three ways back
    FAQ.md                  the five places people get stuck
    CHECKSUMS.md            sha256 of everything you download

## Status

LineageOS 20.0, GSI `arm64_bvN-vndklite` built by Andy Yan.

Android 14 (LineageOS 21) does not boot here: infinite bootloop, with AVB already disabled. Stick to
20.

There is no way to limit battery charging from software on this device. See docs/04.

## Credit

TomKing062 wrote the unlock method and `spd_dump`; without them this tablet stays a paperweight. Andy
Yan builds the GSIs. What is specific to this tablet — which files, in what order, and the traps — was
worked out and verified on hardware for this repository.

Code is MIT, documents are CC BY-SA 4.0. The binaries attached to the Releases are neither: they
belong to Blackview and to TomKing062. Per-file provenance is in
[artifacts/README.md](artifacts/README.md).
