# Che cosa si scarica, e con quale impronta

Verifica sempre con `sha256sum <file>`. L'installer controlla da solo la GSI. **Nessuna impronta qui
sotto è scritta a mano**: sono generate dai file reali al momento della release.

## GSI — LineageOS 20 (Andy Yan)

| | |
|---|---|
| file | `lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img` (2,2 GB, non compressa) |
| sha256 | `3b5ad7fc32bc59321a936f001d427602bc6942dbe4338238618f8d916375ef6e` |
| fonte | <https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/> |

Il `.img.gz` va decompresso **prima** di calcolare lo sha256: quello qui sopra è dell'immagine
scompattata.

## Firmware stock — per il recupero

| | |
|---|---|
| asset della Release | `DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz` (1,9 GB) |
| sha256 del `.gz` | `0f7dd60dd51f22f0c4e7099393d698676d703327fe3f3eb6ac676ca61524b362` |
| sha256 del `.pac` scompattato | `e0531f310597b4bd4ee0bad232640a4eecfc2c11a2776d27ee955df3c6d30d8c` |
| board dichiarata | `s9863a1h10`, la stessa del tablet |

Si ottiene con `gunzip DK_....pac.gz` (3,6 GB scompattati). È una **copia specchio** di un firmware
Blackview già distribuito pubblicamente: se sei il titolare dei diritti e vuoi la rimozione, apri una
issue.

## Kit di sblocco

| | |
|---|---|
| file | `unlock-kit.tar.gz` (716 KB) |
| sha256 | `811d28d52306fc843cad28a19ad7b0060d2cce9e25072996a972cf7599906fb9` |

Il tarball contiene il proprio `SHA256SUMS`: si verifica da solo con
`sha256sum -c SHA256SUMS` dopo averlo estratto.

| file | sha256 |
|---|---|
| `fdl1-dl.bin` | `bffd6edaf4ba07a57bc0db7ee96046bd772113de09ca308caf5537d660ddfbc5` |
| `fdl2-cboot.bin` | `c619fdc146bf778c1a3d92475f88c87f95f1b2ecee4efaa2577fe06bfe3c5dcd` |
| `fdl2-dl.bin` | `ec087b5dfea37874cd81d5edbc689739f60299841f6fb5622065555dcbebf294` |
| `misc-wipe.bin` | `bd6b67e852d6072e6fb87040f2ac40216d5b661b7fa661e7024569ecf8ddb3a7` |
| `spl-unlock.bin` | `fa7f2fd297267c68492b31764ee5fd3461ff27b3d0240a32dc92a25d0af3ca83` |
| `vbmeta-sign.img` | `b2eae2954847900dcc268b58f3348e45adb1656c255347448181431ec24876cc` |
| `vbmeta_system.img` | `000570daf799b6c25d185e2940a3d7531f953822fe949f71d99a898a24076993` |
| `vbmeta_vendor.img` | `ccc565fa59049bf0df790162fc960451b935b11302f4971923b16e351eb6e947` |

## Regola

**Non vuoi fidarti dei binari?** Rigenerali dai tuoi file: la procedura sta in
[`artifacts/README.md`](artifacts/README.md). Non devi fidarti di nessuno.
