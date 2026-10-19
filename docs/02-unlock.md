# Unlocking the bootloader

`fastboot flashing unlock` answers `Not implemet.` and `fastboot oem unlock` answers `unknown cmd.`
The unlock happens in the BootROM instead.

TomKing062's CVE-2022-38694 loads a small payload into RAM that runs with BootROM privileges and
drops the signature checks. Signed FDLs taken from the stock firmware are loaded after it, and from
there `splloader`, `uboot` and `trustos` can be written. The method is his; what follows is the
sequence for this tablet.

## Download mode

Tablet off, hold Vol- and plug the cable, keep holding about ten seconds. The screen stays black and
the tablet appears as `1782:4d00` for roughly thirty seconds. `spd_dump --wait` sits waiting for it,
which is why the installer asks you to press Enter first and do the key combo after.

## 1. Save the bootloaders, erase the SPL stage, install a permissive uboot

    spd_dump --wait 300 exec_addr 0x4ee8 \
      fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
      blk_size 0x8000 r splloader r uboot \
      e splloader e splloader_bak \
      w uboot fdl2-cboot.bin reset

`r splloader r uboot` saves your own bootloaders. They are what you write back at the end, so do not
skip it and do not use somebody else's.

`e splloader` and `e splloader_bak` erase the stage the BootROM would load from flash. The tablet
stops booting normally at this point. That is intended.

`w uboot fdl2-cboot.bin` installs an uboot that does not check the signature of the next stages.

## 2. The unlock

    spd_dump --wait 300 exec_addr 0x4ee8 fdl spl-unlock.bin 0x5000

`spl-unlock.bin` is your own `splloader` with the signature checks replaced by 73 `NOP`s.
`gen_spl-unlock-legacy`, run on the dump from step 1, produces it.

The command looks like it fails. It prints `usb_recv failed` and timeouts and stops. That is the
expected outcome: the patched SPL does not wait for the PC, it boots the patched uboot and that writes
the unlock record. There is nothing to fix, and no answer is coming.

## 3. Check it worked

    spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
      blk_size 0x8000 read_part miscdata 8192 64 m_after.bin reset

Sixty-four zero bytes means still locked, run step 2 again. Thirty-two bytes followed by two 16-byte
hashes means unlocked: that is the record the bootloader writes at offset `0x2000` of `miscdata`.

## 4. Turn AVB off

    spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
      blk_size 0x8000 dis_avb reset

`dis_avb` patches your own `trustos`, which is where the signature check that matters actually runs,
and writes it back.

## 5. Put the bootloaders back

Write the `splloader` and `uboot` saved in step 1. The unlock is already recorded in `miscdata`, so
they do not need to be patched. The tablet boots again after this, still on stock Android unless you
have already flashed the GSI.

## Why only one firmware

`spl-unlock.bin`, `fdl2-cboot.bin` and `fdl1-dl.bin` come from one firmware. On a tablet with another
one they are the wrong images: it will not boot and you need that tablet's own `.pac`. The installer
checks `ro.fota.version` for this reason.

## Reading

- [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader), the wiki pages [Unlock](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/Unlock), [SupportList](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/SupportList) and [AddSupportToModel](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
- [NCC Group on the Unisoc BootROM flaws](https://research.nccgroup.com/2022/09/02/theres-another-hole-in-your-soc-unisoc-rom-vulnerabilities/)
