# FAQ — the five traps

These are the places where people actually get stuck. We paid for each one.

---

## 1. `spd_dump` sits forever on "Waiting for dl_diag connection"

**Even though the tablet is plugged in and the USB node has the right permissions.**

It is not the tablet: `spd_dump` relies on **libusb hotplug**, which on Linux listens for **udevd**
events. If `udevd` is not running (containers, minimal systems, read-only `/sys`) the program waits
forever.

Check:

```
systemctl is-active systemd-udevd
```

If it is not active:

```
sudo systemctl start systemd-udevd
# or, if systemd skips it because of an unmet condition:
sudo nohup /lib/systemd/systemd-udevd &
```

Related symptom, same family: `libusb_claim_interface failed : LIBUSB_ERROR_BUSY`.

---

## 2. `LIBUSB_ERROR_BUSY` when claiming the interface

The tablet has a **single** USB interface: either another program holds it, or the tool itself does.

- **Another program**: `sudo pkill -x spd_dump`, and stop `adb` (`adb kill-server`) before running
  `spd_dump`. Two `spd_dump` processes never work together.
- **The tool itself**: some versions open the device twice and the second claim collides with the
  first. If that happens, update `spd_dump` to the latest build of TomKing062's fork.

---

## 3. `install.sh unlock` says the SPL step failed (but it worked)

The output contains:

```
usb_recv failed : LIBUSB_ERROR_TIMEOUT
CHECK_BAUD FAIL
usb_send failed : LIBUSB_ERROR_TIMEOUT
```

**This is expected.** `spl-unlock.bin` does not wait for the PC: it runs, loads the patched `uboot`,
and that writes the unlock data. The tool gets no answer and looks dead.

The real proof is the `miscdata` check:

```
spd_dump ... read_part miscdata 8192 64 m_after.bin
```

- 64 bytes **all zero** → not unlocked, repeat the step.
- 32 bytes + 16 + 16 → **unlocked**.

Do not "fix" that timeout: it is not an error.

---

## 4. `fastboot erase` answers `Erasing failed`

This bootloader does not implement `erase` for `userdata`, `metadata` and `misc`. Work around it by
**flashing an image** of zeros over them:

```
# misc (1 MB) — needed to clear the "boot-fastboot" command so Android boots again
dd if=/dev/zero of=misc-zero.img bs=1M count=1
fastboot flash misc misc-zero.img
```

For `userdata` the wipe is done from recovery (Wipe data/factory reset) or from the tool in download
mode (it writes the wipe command into `misc` and erases `metadata`).

---

## 5. After flashing it stays on the Blackview logo (bootloop)

In order of likelihood:

1. **`misc` still contains `boot-fastboot`** → the tablet does not even try to boot Android. Zero
   `misc` (see point 4).
2. **`product` was not recreated** → the vendor fstab mounts it and init never finishes.
   `fastboot create-logical-partition product 0x4000000` + `flash product` with an empty ext4.
3. **Wrong GSI**: **Android 14 does not boot** on this vendor. You need the **20 (Android 13)**,
   `arm64_bvN-vndklite`. With A14 the loop happens even with AVB fully disabled — do not waste days.
4. **Old data**: if you never wiped, Android 10's `userdata` cannot be mounted by Android 13.

To find out *where* it stops, read the bootloader log:

```
spd_dump ... read_part uboot_log 0 0x400000 uboot_log.bin
strings uboot_log.bin | grep -E "veritymode|enter mode|Error"
```

---

## Extra: `adb` does not see the tablet (or "no permissions")

- In **download** mode the tablet is not an Android device: `adb` cannot see it, that is normal.
- After installing LineageOS it **does not expose a serial over USB**: a udev rule keyed on the serial
  no longer matches. Use VID-based rules (`1782` and `18d1`, see
  [`01-preparation.md`](01-preparation.md)).
- `user X is not in the plugdev group` is adb's generic message when it cannot open the node: almost
  always udev permissions, not the group.
