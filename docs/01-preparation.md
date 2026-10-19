# Preparation

## 1. Tools on the PC (Debian/Ubuntu)

```
sudo apt install -y adb fastboot build-essential libusb-1.0-0-dev libxml2-dev pkg-config unzip e2fsprogs
```

You also need **`spd_dump`**, the program that talks to the BootROM. It is not packaged: build it from
TomKing062's fork (the one that speaks this SoC's protocol):

```
git clone --recursive https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader.git
cd CVE-2022-38694_unlock_bootloader/spreadtrum_flash && make
```

The binary is `spreadtrum_flash/spd_dump`. Put it in your `PATH` or set `SPD_DUMP=/path/to/spd_dump`.

## 2. USB permissions

Without udev rules, `adb`, `fastboot` and `spd_dump` cannot open the tablet. Create
`/etc/udev/rules.d/51-bvtab8.rules`:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666"
```

Then:

```
sudo udevadm control --reload && sudo udevadm trigger --action=add --subsystem-match=usb
```

The tablet shows up with **two different IDs depending on the mode** (this is normal):

| mode | VID:PID |
|---|---|
| download mode (BootROM / firmware download) | `1782:4d00` |
| Android / fastboot | `18d1:4ee8`, `18d1:4ee0` |

## 3. Files to download

The installer fetches them itself (`./install.sh check`) and verifies the sha256 from
[`CHECKSUMS.md`](../CHECKSUMS.md). To do it by hand:

| file | where | why |
|---|---|---|
| **GSI** `lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img.gz` | [SourceForge — Andy Yan](https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/) | the system that gets installed |
| **Stock firmware** `DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz` (1.9 GB) | [Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases) | safety net + FDLs + vbmeta; `gunzip` → 3.6 GB |
| **Unlock kit** (`unlock-kit.tar.gz`, or the eight files individually) | [Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases) | everything needed to unlock |

> The available `.pac` is **NEU 2020**, while the tablet ships **EEA 2021**: for recovery that is fine
> (same board, `s9863a1h10`), but restoring stock gives you Android 10 NEU, not the exact EEA build.
> A dump of the exact stock system is *not* included — we never took one.

## 4. Sanity check

Boot the tablet, enable USB debugging (Settings → About → tap "Build number" 7× → Developer options
→ USB debugging), then:

```
./install.sh check
```

It verifies: tools, USB permissions, the device being reachable, and the **supported firmware**.
If the firmware does not match, the installer stops — that check is the most important protection of
the whole procedure (the unlock artifacts are firmware-specific).
