# LineageOS 20 on the Blackview Tab 8 (Unisoc SC9863A)

Guide and tooling to install **LineageOS 20 (Android 13)** on a **Blackview Tab 8** (Unisoc SC9863A,
4/64 GB) — a 2020 tablet abandoned by its vendor, with **no kernel source and no device tree**.

Verified on real hardware: LineageOS 20 with **wifi, touch, audio, auto-rotation and brightness
working**.

> ⚠️ **Read [`docs/00-risks.md`](docs/00-risks.md) before touching anything.**
> You will unlock the bootloader (all data gone), write to bootloader partitions, and wipe the stock
> system. It is recoverable — but only if you have the stock firmware at hand.

## How it works, in three lines

This tablet's bootloader **cannot be unlocked from fastboot** (`fastboot flashing unlock` answers
`Not implemet.`). It is unlocked from the **BootROM** instead, using
[CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) — the project by
TomKing062, who did all the hard work. Then a LineageOS **GSI** (Generic System Image) is flashed over
the stock `system`, and AVB is disabled.

## Requirements

- A **Linux PC** (x86_64). Windows is not supported (SPRD and libusb drivers conflict there).
- A tablet running firmware **`Tab8_EEA_P30_V1.0_20211112V11`**. The installer checks this and
  refuses otherwise: the unlock artifacts are **firmware-specific**.
- A USB **data** cable (not charge-only).
- ~5 GB of free disk space.

## Install

```
git clone https://github.com/Elkon/blackview-tab8-lineageos.git
cd blackview-tab8-lineageos
./install.sh check      # tools, permissions, device, firmware
./install.sh unlock     # unlock the bootloader (physical key combos required)
./install.sh flash      # install LineageOS 20
```

Every step explains what it is about to do, asks for confirmation, and stops if something is off.
`--dry-run` prints the commands without running them.

## Repository layout

```
install.sh              the wizard (check / unlock / flash / wipe / verify / restore)
artifacts/              unlock kit for this firmware (+ per-file links, checksums, how to rebuild)
docs/00-risks.md        what breaks, what is irreversible, how to recover
docs/01-preparation.md  tools, USB permissions, files to download
docs/02-unlock.md       the unlock procedure, step by step
docs/03-flash-gsi.md    fastbootd, dynamic partitions, vbmeta chain, wipe
docs/04-post-install.md  hardware check and tuning
docs/05-recovery.md     three levels of "go back"
FAQ.md                  the five traps everybody hits
CHECKSUMS.md            sha256 of everything you download
```

## Status

| | |
|---|---|
| LineageOS | **20.0** (Android 13), GSI `arm64_bvN-vndklite` by [Andy Yan](https://sourceforge.net/projects/andyyan-gsi/) |
| Hardware | wifi, touch, audio, rotation, brightness ✅ — camera and LTE modem untested |
| Android 14 (LineageOS 21) | **does not boot** on this vendor: infinite bootloop. Don't waste days, see FAQ |
| Known limits | no software battery-charge limit (see `docs/04`) |

## Credits

- **[TomKing062](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)** — the unlock
  method (CVE-2022-38694) and [`spd_dump`](https://github.com/TomKing062/spreadtrum_flash). Without
  his work this tablet would be a paperweight.
- **Andy Yan** — the TrebleDroid-based LineageOS GSIs.
- The Tab 8-specific recipe (which files, in which order, and the traps) was verified on real
  hardware by this repository.

License: **code MIT**, **docs CC BY-SA 4.0** (see `LICENSE` and `LICENSE-docs`).

The **binaries** in the Releases are *not* covered by those licenses: they are vendor files
(Blackview/Unisoc) and TomKing062's. Per-file provenance, how to regenerate them or avoid them
entirely: [`artifacts/README.md`](artifacts/README.md).
