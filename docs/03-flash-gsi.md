# Installing the GSI

Needs the bootloader unlocked first. `./install.sh flash` runs this.

## fastbootd

`system`, `vendor` and `product` are not real partitions here. They are logical partitions inside a
4 GB container called `super`, so normal fastboot has nothing to write to. fastbootd, the userspace
one, resizes them.

The tablet has it. `adb reboot fastboot`, then `fastboot getvar is-userspace` answers `yes`.

## Space

`super` is 4.00 GB. Inside it `system` is 1.49 GB, `product` 1.48 GB, `vendor` 0.39 GB, which leaves
about 650 MB free.

The GSI is 2.4 GB, so it does not fit until `product` is gone. The stock product partition is useless
to a GSI anyway. Without that step fastboot answers `Not enough space to resize partition`.

## The sequence

    adb reboot fastboot
    fastboot devices

    fastboot delete-logical-partition product
    fastboot flash system lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img

    fastboot --disable-verity --disable-verification flash vbmeta        vbmeta-sign.img
    fastboot --disable-verity --disable-verification flash vbmeta_system vbmeta_system.img
    fastboot --disable-verity --disable-verification flash vbmeta_vendor vbmeta_vendor.img

    fastboot create-logical-partition product 0x4000000
    fastboot flash product product-empty.img

    adb reboot recovery          # then "Wipe data/factory reset" on the tablet
    fastboot flash misc misc-zero.img
    fastboot reboot

`./install.sh wipe` does the data wipe from download mode instead of recovery. `misc-zero.img` is a
1 MB file of zeros; `product-empty.img` is a 64 MB ext4 with nothing in it, `mkfs.ext4 -L product`
makes it.

## Things that cost us time

`fastboot erase` does not work on this bootloader, it answers `Erasing failed`. Erasing `userdata`,
`metadata` or `misc` means flashing an image of zeros over them.

`misc` holds the boot command. If `boot-fastboot` is left in there the tablet boots fastboot forever
and never tries Android. Zeroing it is not optional.

All three vbmeta images need the flags. Patching only the main `vbmeta` changes nothing, `veritymode`
stays `enforcing`.

The vbmeta signature stops matching once the flags are edited. With the bootloader unlocked AVB
tolerates that and honours the flags. Every GSI does this.

Android 14 does not boot on this vendor. Use 20.

## When it stays on the logo

The order of suspicion: `misc` still says `boot-fastboot`, `product` was not recreated, the GSI is the
Android 14 one, or the data was never wiped.

The bootloader log tells you where it stopped. Read it from download mode with
`read_part uboot_log 0 0x400000 uboot_log.bin` and look for `androidboot.veritymode` and
`enter mode`.
