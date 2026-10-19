# Risks

The procedure unlocks the bootloader and writes to bootloader partitions. It is not undone by
running something in reverse.

## What is gone for good

All data on the tablet. Unlocking and installing a GSI both wipe `userdata`.

The stock Blackview system, and whatever is left of the warranty.

The "unlock" warning at every boot, for as long as the bootloader stays unlocked.

## What can go wrong

A bootloop after flashing is the usual accident, and it is fixed by reflashing the bootloaders from
the kit or by going back to stock.

A wrong write to `splloader` or `uboot` stops the tablet from booting normally. The only way back is
download mode: tablet off, hold Vol-, plug the cable. If it will not enter download mode, the case has
to be opened and the battery disconnected.

The BootROM itself is not touched; the exploit runs in RAM. That is why download mode keeps working
and why these failures are recoverable at all.

## Before starting

Have the stock firmware. The `.pac` is the safety net: if the tablet stops booting, everything is
rewritten from it. The installer fetches it during `check`, or asks where it is.

Check the firmware. `spl-unlock.bin` and `fdl2-cboot.bin` are built from one particular firmware.
On a Tab 8 with a different one they are incompatible images and the tablet will not boot. The
installer compares `ro.fota.version` with `Tab8_EEA_P30_V1.0_20211112V11` and stops if it does not
match. Do not work around that.

One program at a time. There is a single USB interface: two `spd_dump` processes make everything fail
with `LIBUSB_ERROR_BUSY`. Stop `adb` as well.

Do not unplug during a write. If it happens the tablet stays in download mode and you start over.

Battery above 50%.

## Not covered

Windows and macOS.

Tablets with another firmware.

LineageOS OTA updates: with a GSI, every update is a reflash.

Camera and LTE modem, never tested. The vendor side is still from 2021.
