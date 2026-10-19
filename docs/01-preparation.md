# Preparation

## Tools

Debian or Ubuntu:

    sudo apt install -y adb fastboot build-essential libusb-1.0-0-dev libxml2-dev pkg-config unzip e2fsprogs

`spd_dump` talks to the BootROM and is not packaged. Build it from TomKing062's fork, which speaks
this SoC's protocol:

    git clone --recursive https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader.git
    cd CVE-2022-38694_unlock_bootloader/spreadtrum_flash && make

The binary is `spreadtrum_flash/spd_dump`. Leave it in `PATH` or set `SPD_DUMP=/path/to/spd_dump`.

## USB permissions

Without udev rules adb, fastboot and spd_dump cannot open the device. Write
`/etc/udev/rules.d/51-bvtab8.rules`:

    SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666"

then

    sudo udevadm control --reload && sudo udevadm trigger --action=add --subsystem-match=usb

The tablet shows two different IDs depending on the mode it is in. `1782:4d00` is download mode, the
only one that matters for unlocking. Android and fastboot come up as `18d1:4ee8` and `18d1:4ee0`.

## Downloads

`./install.sh check` fetches these and verifies the hashes in [CHECKSUMS.md](../CHECKSUMS.md). By hand:

The GSI is `lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img.gz`, from
[SourceForge](https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/). Gunzip it.

The stock firmware is `DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz`, 1.9 GB, from the
[Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases) or the
[archive.org mirror](https://archive.org/details/blackview-tab8-sc9863a-firmware). It is the recovery
image, and it also holds the FDLs and the vbmeta images that are already in the kit. Gunzip it and you
get 3.6 GB.

The unlock kit is `unlock-kit.tar.gz`, 716 KB, from the Releases. Extract it into
`artifacts/unlock-kit/`.

The `.pac` is the NEU build from 2020 while the tablet ships EEA 2021. For recovery that is fine, same
board, but restoring stock gives Android 10 NEU rather than the EEA build it left the factory with.
Nobody ever dumped that one.

## Before you start

Turn the tablet on, enable USB debugging (Settings, About, tap Build number seven times, Developer
options, USB debugging), then:

    ./install.sh check

It checks the tools, the udev permissions, whether the tablet is reachable, and the firmware version.
If the firmware does not match it stops there.
