# Installing the GSI (LineageOS 20)

Assumes the bootloader is unlocked ([`02-unlock.md`](02-unlock.md)). Automated by
`./install.sh flash`.

## Why fastbootd is required

The Tab 8 uses **dynamic partitions**: `system`, `vendor` and `product` are not physical partitions but
**logical** ones inside a container called `super` (4 GB). In normal fastboot `system` does not exist
as something you can flash: you need **fastbootd**, the userspace fastboot that can resize logical
partitions.

This tablet has it: `adb reboot fastboot` → `fastboot getvar is-userspace` answers `yes`.

## Space: the constraint that drives everything

| partition | size |
|---|---|
| `super` | 4.00 GB |
| `system` | 1.49 GB |
| `product` | 1.48 GB |
| `vendor` | 0.39 GB |
| **free** | **~650 MB** |

The `vndklite` GSI we need is **2.2 GB**: it does not fit while `product` takes 1.48 GB. That is why
the sequence starts by **deleting `product`** (the stock Android 10 product is useless to a GSI; and
without space, fastboot answers `Not enough space to resize partition`).

## The sequence

```
adb reboot fastboot                     # into fastbootd
fastboot devices                        # must list the tablet

fastboot delete-logical-partition product
fastboot flash system lineage-20.0-...-arm64_bvN-vndklite.img      # ~2 min

# AVB: all THREE vbmate images (the chain is vbmeta -> vbmeta_system / vbmeta_vendor)
fastboot --disable-verity --disable-verification flash vbmeta        vbmeta-sign.img
fastboot --disable-verity --disable-verification flash vbmeta_system vbmeta_system.img
fastboot --disable-verity --disable-verification flash vbmeta_vendor vbmeta_vendor.img

# the vendor fstab mounts product in first stage: recreate it
fastboot create-logical-partition product 0x4000000     # 64 MB
fastboot flash product product-empty.img

# wipe user data
adb reboot recovery        # then "Wipe data/factory reset" on the tablet
# or, without recovery: ./install.sh wipe   (writes the wipe command into misc, erases metadata)

# clear the boot command left in misc
fastboot flash misc misc-zero.img

fastboot reboot
```

## Notes that save hours

- **`fastboot erase` does not work** on this bootloader (`Erasing failed`): to "erase" `userdata`,
  `metadata` or `misc` you **flash an image** (zeros) over them.
- **`misc` carries the boot command**: if `boot-fastboot` stays in there (written by
  `reboot-fastboot`) the tablet always boots fastboot and never even tries Android. That is why it
  must be zeroed.
- **`--disable-verity` and `--disable-verification` are both needed**, and on **all three** vbmeta
  images: patching only the main `vbmeta` changes nothing (verified: `veritymode` stays `enforcing`).
- **The `vbmeta` signature no longer matches** after patching. With an unlocked bootloader AVB tolerates
  it and honours the flags: this is the standard GSI trick.
- **Android 14 (LineageOS 21) does not boot** on this vendor: bootloop, even with AVB fully disabled.
  Use the 20 (Android 13).

## If the tablet stays on the logo

1. Bootloop after flashing → something is missing: `product` not recreated, `misc` not cleaned, or the
   wrong GSI (A14).
2. To see what the bootloader did before handing over: read `uboot_log` (4 MB) with
   `spd_dump ... read_part uboot_log 0 0x400000 uboot_log.bin` and grep for `androidboot.veritymode`
   and `enter mode`.
3. To go back: [`05-recovery.md`](05-recovery.md).
