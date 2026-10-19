# Checksums

`sha256sum <file>` and compare. The installer checks the GSI itself. The values below were generated
from the actual files when the release was made, not typed by hand.

## GSI

`lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img`, 2.4 GB, uncompressed.

    3b5ad7fc32bc59321a936f001d427602bc6942dbe4338238618f8d916375ef6e

From <https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/>. The archive there is
gzipped: gunzip it before hashing, the value above is for the image.

## Stock firmware

`DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz`, 1.9 GB, Release asset and
[archive.org mirror](https://archive.org/details/blackview-tab8-sc9863a-firmware).

    0f7dd60dd51f22f0c4e7099393d698676d703327fe3f3eb6ac676ca61524b362

Gunzipped it is 3.6 GB and hashes to

    e0531f310597b4bd4ee0bad232640a4eecfc2c11a2776d27ee955df3c6d30d8c

The archive declares board `s9863a1h10`, the same as this tablet. It is a mirror of firmware Blackview
already distributes publicly; if you hold the rights and want it removed, open an issue.
## Unlock kit

`unlock-kit.tar.gz`, 716 KB, from the Releases.

    811d28d52306fc843cad28a19ad7b0060d2cce9e25072996a972cf7599906fb9

The tarball carries its own `SHA256SUMS`. Extract and run `sha256sum -c SHA256SUMS`.

Per-file values, for checking a file you already have:
    bffd6edaf4ba07a57bc0db7ee96046bd772113de09ca308caf5537d660ddfbc5  fdl1-dl.bin
    c619fdc146bf778c1a3d92475f88c87f95f1b2ecee4efaa2577fe06bfe3c5dcd  fdl2-cboot.bin
    ec087b5dfea37874cd81d5edbc689739f60299841f6fb5622065555dcbebf294  fdl2-dl.bin
    bd6b67e852d6072e6fb87040f2ac40216d5b661b7fa661e7024569ecf8ddb3a7  misc-wipe.bin
    fa7f2fd297267c68492b31764ee5fd3461ff27b3d0240a32dc92a25d0af3ca83  spl-unlock.bin
    b2eae2954847900dcc268b58f3348e45adb1656c255347448181431ec24876cc  vbmeta-sign.img
    000570daf799b6c25d185e2940a3d7531f953822fe949f71d99a898a24076993  vbmeta_system.img
    ccc565fa59049bf0df790162fc960451b935b11302f4971923b16e351eb6e947  vbmeta_vendor.img

The kit can be rebuilt from your own files instead, see
[artifacts/README.md](artifacts/README.md).
