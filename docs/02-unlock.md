# Unlocking the bootloader (BootROM, CVE-2022-38694)

This tablet's fastboot **does not implement unlocking**: `fastboot flashing unlock` answers
`Not implemet.` and `fastboot oem unlock` answers `unknown cmd.`. The only way in is the **BootROM**,
using [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) by TomKing062:
a tiny payload is loaded into RAM, it bypasses the BootROM signature check, signed FDLs taken from the
firmware are loaded, and from there bootloader partitions can be written.

**All the credit for the method is his.** What follows is just the Tab 8 recipe.

## What the exploit does, briefly

Unisoc verifies the signature of everything the PC sends to the BootROM. The payload
(`custom_exec_no_verify_4ee8.bin`, 128 bytes) abuses a flaw that allows executing code with BootROM
privileges: from there signature checks no longer apply and you can load your own `fdl1`/`fdl2` and
write `splloader`, `uboot`, `trustos`.

## The sequence (`./install.sh unlock` automates it)

Enter **download mode**: tablet off, hold **Vol‑**, plug the cable, keep holding ~10 s. The tablet
appears as `1782:4d00` and stays for ~30 seconds — which is why the installer waits first
(`spd_dump --wait`) and then asks you for the key combo.

### 1. Dump your bootloaders, then unlock

```
spd_dump --wait 300 exec_addr 0x4ee8 \
  fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 r splloader r uboot \
  e splloader e splloader_bak \
  w uboot fdl2-cboot.bin reset
```

- `r splloader r uboot` → saves **your own** bootloaders (you need them for the restore; never use
  somebody else's).
- `e splloader e splloader_bak` → erases the stage the BootROM would load from flash. From here the
  tablet no longer boots normally: **that is expected**.
- `w uboot fdl2-cboot.bin` → installs an `uboot` that does not verify later stages.

### 2. The unlock itself

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl spl-unlock.bin 0x5000
```

`spl-unlock.bin` is **your own** `splloader` with the signature checks neutralised (73 `NOP`s):
`gen_spl-unlock-legacy` produces it from the dump taken in step 1.

> ⚠️ **This command "fails", and that is the signal it worked.** The patched SPL does not wait for
> the PC (no `CHECK_BAUD` answer: you will see `usb_recv failed` and timeouts): it moves on, boots the
> patched `uboot`, and *that* writes the unlock data. The real proof is step 3.

### 3. Verify

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 read_part miscdata 8192 64 m_after.bin reset
```

- **64 zero bytes** → still locked: repeat step 2.
- **32 bytes + 16 + 16** (hashes) → **unlocked** (the "legal unlock data" the bootloader writes into
  `miscdata` at `0x2000`).

### 4. Get AVB out of the way

The bootloader would still demand vendor-signed images. `dis_avb` patches **your own** `trustos`
(where Unisoc performs the real verification, through the TEE) and writes it back:

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 dis_avb reset
```

### 5. Restore the original bootloaders

Put back the `splloader` and `uboot` saved in step 1 (the unlock is already recorded in `miscdata`).
From here the tablet boots again — **on stock Android if you have not flashed the GSI yet**, with an
unlocked bootloader.

## Why the firmware matters

`spl-unlock.bin`, `fdl2-cboot.bin` and `fdl1-dl.bin` are derived from **that** firmware. On a Tab 8
with a different one (NEU 2020, ROW, Android 11 OTA) they are incompatible images: the tablet will not
boot and you need *their* `.pac` to get back. The installer verifies `ro.fota.version` and stops on a
mismatch — **do not bypass that check**.

## References

- [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) — tool, payloads, wiki
- Wiki: [Unlock](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/Unlock) ·
  [SupportList](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/SupportList) ·
  [AddSupportToModel](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
- [NCC Group — There's another hole in your SoC](https://research.nccgroup.com/2022/09/02/theres-another-hole-in-your-soc-unisoc-rom-vulnerabilities/) — the flaw analysis
