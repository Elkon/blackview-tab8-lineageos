# Risks, first of all

This procedure **unlocks the bootloader** and **writes to bootloader partitions**. It is not
reversible with one click, and it is not for everyone.

## What you lose, for sure

- **All data on the tablet** (photos, apps, accounts). Unlocking and switching to a GSI wipe
  `userdata`. There is no way around it.
- The **stock Blackview system** and whatever is left of the warranty.
- The **"unlock" warning** at boot: it stays forever, as long as the bootloader is unlocked.

## What you risk, if something goes wrong

| Risk | How bad | How to recover |
|---|---|---|
| Bootloop after flashing | annoying | reflash the bootloaders from the kit, or restore stock |
| Wrong write to `splloader`/`uboot` | **bad**: the tablet no longer boots normally | only by entering **download mode** (Vol‑ + cable) and rewriting them |
| Tablet that will not enter download mode | **very bad** | open the case and **disconnect the battery**; if the BootROM itself is damaged, recovery is uncertain |

This procedure does **not** touch the BootROM (the exploit runs in RAM), so download mode stays
available: that is the reason recovery is realistic at all.

## Rules that are not optional

1. **Have the stock firmware before you start.** The `.pac` is your safety net: if the tablet does not
   boot, you rewrite everything from it. The installer downloads it (or asks you for it) during
   `check`. Without it, do not proceed.
2. **Right firmware.** The unlock artifacts (`spl-unlock.bin`, `fdl2-cboot.bin`) come from **your**
   `splloader` and **your** firmware's FDLs. On a different firmware they are **poison**. The
   installer checks `ro.fota.version` and stops on a mismatch. Do not bypass that check.
3. **One program at a time may talk to the tablet.** There is a single USB interface: two `spd_dump`
   processes make everything fail with `LIBUSB_ERROR_BUSY`. Stop `adb` too.
4. **Do not unplug during a write.** If it happens, the tablet stays in download mode: resume from
   there, it is not the end.
5. **Battery at least 50%** before you start.

## What is not covered

- Windows and macOS. Linux only.
- Tablets with a firmware other than `Tab8_EEA_P30_V1.0_20211112V11` (enforced by the installer).
- LineageOS OTA updates: with a GSI every update is a reflash.
- Camera and LTE modem: untested (the vendor side is still the 2021 one).

If anything here is unclear to you, **stop**: a tablet that does not power on is a much bigger problem
than a tablet on stock Android 10.
