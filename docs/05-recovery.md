# Going back

There are three levels of "go back". Pick according to what you broke.

## A. Bootloop, but download mode still works

**The common case.** You do not need the stock firmware: the original bootloaders are enough — the
installer saves them before touching anything (`backups/splloader`, `backups/uboot`,
`backups/miscdata.bin`).

```
./install.sh restore
```

It writes back the original `splloader`, `uboot` and `miscdata`. If the system (the GSI) is healthy, it
boots again.

If you flashed a wrong GSI (Android 14, for instance) and it loops, restoring the bootloaders is not
enough: reflash the right `system` ([`03-flash-gsi.md`](03-flash-gsi.md)) or go back to stock (B).

## B. Back to stock Android 10 (Blackview)

You need the `.pac` — a Release asset of this repository, mirrored on
[archive.org](https://archive.org/details/blackview-tab8-sc9863a-firmware) (1.9 GB `.gz`, `gunzip` it
first). From download mode, with `spd_dump`:

```
spd_dump --wait 300 exec_addr 0x4ee8 \
  fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 \
  w_force super super.img \
  w splloader splloader-stock.bin \
  w uboot uboot-stock.bin \
  w trustos trustos-stock.bin \
  reset
```

The `*-stock` images are extracted from the `.pac` with `unpac` (bundled with `spreadtrum_flash`):

```
./unpac list DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac
./unpac -d extracted extract DK_....pac super.img u-boot-spl-16k-sign.bin u-boot-sign.bin tos-sign.bin
```

> The available `.pac` is **NEU 2020**: you get a working Android 10, but not the EEA 2021 build the
> tablet shipped with (that was never dumped). The tablet is fully usable again, and it stays
> **unlocked**.

The official route is `ResearchDownload` (Windows) or `Factory Download` with the same `.pac`, which
rewrites everything — that is what the "unbrick" guides use.

## C. The tablet will not enter download mode

**The bad case.** If holding **Vol‑** while plugging the cable does not make `1782:4d00` appear:

1. **Unplug the cable** (in charging mode the tablet is invisible to the PC) and force a power-off with
  **Power for 15–20 s**.
2. Retry holding **Vol‑** *before* plugging the cable, and keep holding ~10 s.
3. Also try **Vol+**, or **Power + Vol‑** together.
4. If nothing works: **open the case and disconnect the battery** for a few seconds, then reconnect and
   retry. Several people recovered tablets given up for dead this way (sometimes it was just a fully
   drained battery).

## What NOT to do

- Do not write `splloader`/`uboot` with images from **another** tablet or another firmware: it is the
  fastest way to turn a bootloop into a paperweight.
- Do not remove the battery with the cable plugged in.
- Do not interrupt a `super` write (4 GB): if it happens the tablet stays in download mode and you
  repeat it — not fatal, but you need the `.pac`.
