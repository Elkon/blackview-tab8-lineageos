# FAQ

Five places where this goes wrong and the fix is not obvious.

## spd_dump waits on "Waiting for dl_diag connection" forever

The tablet is plugged in and the device node has the right permissions, and nothing happens.

spd_dump uses libusb hotplug, which on Linux listens for udevd events. If udevd is not running, in a
container for example or on a minimal system with read-only /sys, the program waits forever.

`systemctl is-active systemd-udevd` tells you. If it is not active, `sudo systemctl start
systemd-udevd`, or start the daemon directly if systemd skips it because of an unmet condition:

    sudo nohup /lib/systemd/systemd-udevd &

## LIBUSB_ERROR_BUSY

The tablet has one USB interface. Either another program holds it or the tool opened it twice.

Another program is the common case: `sudo pkill -x spd_dump` and `adb kill-server`, then run
spd_dump alone. Two spd_dump processes never work at the same time.

The tool doing it to itself was a bug in some builds, where the device got opened twice and the
second claim collided with the first. Updating spd_dump to the latest build of TomKing062's fork
avoids it.

## The unlock step reports failure and it worked

You see this:

    usb_recv failed : LIBUSB_ERROR_TIMEOUT
    CHECK_BAUD FAIL
    usb_send failed : LIBUSB_ERROR_TIMEOUT

The patched SPL does not answer the PC. It runs, boots the patched uboot, and that writes the unlock
record. The tool gets silence and looks broken.

Read `miscdata` to find out which it is:

    spd_dump ... read_part miscdata 8192 64 m_after.bin

All zeros means not unlocked, do it again. Thirty-two bytes plus two 16-byte hashes means unlocked.

## fastboot erase answers "Erasing failed"

`erase` is not implemented for `userdata`, `metadata` and `misc` on this bootloader. Flash zeros over
them instead:

    dd if=/dev/zero of=misc-zero.img bs=1M count=1
    fastboot flash misc misc-zero.img

`userdata` is wiped from recovery, or from download mode with `./install.sh wipe`.

## It stays on the Blackview logo

Most likely, in this order:

`misc` still carries `boot-fastboot`, so the tablet never tries Android. Zero `misc`.

`product` was not recreated. The vendor fstab mounts it and init does not get to the end.
`fastboot create-logical-partition product 0x4000000` and flash the empty ext4 into it.

The GSI is the Android 14 one. Android 14 does not boot on this vendor, with or without AVB.

The data was never wiped, so Android 10's userdata cannot be mounted by Android 13.

The bootloader log says where it stopped:

    spd_dump ... read_part uboot_log 0 0x400000 uboot_log.bin
    strings uboot_log.bin | grep -E "veritymode|enter mode|Error"

## adb does not see the tablet

In download mode it is not an Android device, so adb cannot see it and that is normal.

LineageOS does not put a serial number on the USB descriptor. A udev rule keyed on the serial, which
works on stock, stops matching. Use the VID rules from
[docs/01-preparation.md](docs/01-preparation.md).

`user X is not in the plugdev group` is what adb prints whenever it cannot open the node. It is
almost always udev permissions, not the group.
