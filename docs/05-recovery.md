# Going back

Three cases. Pick by what broke.

## The tablet loops but download mode works

You do not need the stock firmware for this one. The original bootloaders are enough, and the
installer saved them before touching anything in `backups/`.

    ./install.sh restore

That writes back `splloader`, `uboot` and `miscdata`. If only the system was broken it boots again.

If you flashed the wrong GSI, Android 14 for instance, restoring the bootloaders is not enough:
reflash the right `system`, or go back to stock below.

## Back to stock Android 10

Needs the `.pac`: a Release asset of this repository, mirrored on
[archive.org](https://archive.org/details/blackview-tab8-sc9863a-firmware). It arrives gzipped, so
`gunzip` it first.

From download mode:

    spd_dump --wait 300 exec_addr 0x4ee8 \
      fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
      blk_size 0x8000 \
      w_force super super.img \
      w splloader splloader-stock.bin \
      w uboot uboot-stock.bin \
      w trustos trustos-stock.bin \
      reset

The `*-stock` images come out of the `.pac` with `unpac`, which ships with `spreadtrum_flash`:

    ./unpac list DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac
    ./unpac -d extracted extract DK_....pac super.img u-boot-spl-16k-sign.bin u-boot-sign.bin tos-sign.bin

This is the NEU build from 2020, so you get a working Android 10 but not the EEA 2021 build the tablet
shipped with. It stays unlocked, and it is fully usable.

The other route is `ResearchDownload` or `Factory Download` on Windows with the same `.pac`, which
rewrites everything. That is what the unbrick guides use.

## It will not enter download mode

Tablet off, hold Vol-, plug the cable, and `1782:4d00` does not appear.

Unplug the cable first: in charging mode the tablet is invisible to the PC. Force the power off with
Power held for fifteen or twenty seconds. Then try again with Vol- held before the cable goes in, and
keep holding for about ten seconds. Vol+ alone, or Power with Vol-, sometimes works where Vol- does
not.

If none of that produces a device, the case has to be opened and the battery disconnected for a few
seconds. People have recovered tablets given up for dead this way, sometimes because the only problem
was a completely flat battery.

## What not to do

Do not write `splloader` or `uboot` from another tablet or another firmware. That is the quickest way
to turn a bootloop into a tablet that never boots again.

Do not pull the battery with the cable connected.

An interrupted `super` write is not fatal: the tablet stays in download mode and you start again. It
does need the `.pac`.
