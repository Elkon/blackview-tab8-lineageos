# Installazione della GSI (LineageOS 20)

Presuppone il bootloader sbloccato ([`02-unlock.md`](02-unlock.md)). Automatizzato da
`./install.sh flash`.

## Perché serve fastbootd

Il Tab 8 usa **partizioni dinamiche**: `system`, `vendor` e `product` non sono partizioni fisiche ma
**logiche**, dentro un contenitore chiamato `super` (4 GB). Nel fastboot normale `system` non esiste
come partizione da flashare: serve **fastbootd**, il fastboot "in userspace", che sa ridimensionare
le partizioni logiche.

Il tablet ce l'ha: `adb reboot fastboot` → `fastboot getvar is-userspace` risponde `yes`.

## Spazio: il vincolo che decide tutto

| partizione | dimensione |
|---|---|
| `super` | 4,00 GB |
| `system` | 1,49 GB |
| `product` | 1,48 GB |
| `vendor` | 0,39 GB |
| **libero** | **~650 MB** |

La GSI `vndklite` che serve a noi pesa **2,2 GB**: non entra finché `product` occupa 1,48 GB. Per
questo la sequenza comincia **cancellando `product`** (il product stock di Android 10 non serve a una
GSI; e senza spazio `fastboot` risponde `Not enough space to resize partition`).

## La sequenza

```
adb reboot fastboot                     # in fastbootd
fastboot devices                        # deve elencare il tablet

fastboot delete-logical-partition product
fastboot flash system lineage-20.0-...-arm64_bvN-vndklite.img      # ~2 min

# AVB: servono TUTTE E TRE le vbmeta (la catena è vbmeta -> vbmeta_system / vbmeta_vendor)
fastboot --disable-verity --disable-verification flash vbmeta        vbmeta-sign.img
fastboot --disable-verity --disable-verification flash vbmeta_system vbmeta_system.img
fastboot --disable-verity --disable-verification flash vbmeta_vendor vbmeta_vendor.img

# la fstab del vendor monta product in first-stage: va ricreata
fastboot create-logical-partition product 0x4000000     # 64 MB
fastboot flash product product-empty.img

# wipe dei dati
adb reboot recovery        # poi "Wipe data/factory reset" sul tablet
# oppure, senza recovery: ./install.sh wipe   (scrive il comando in misc e cancella metadata)

# pulire il comando di boot rimasto in misc
fastboot flash misc misc-zero.img

fastboot reboot
```

## Note che fanno risparmiare ore

- **`fastboot erase` non funziona** su questo bootloader (`Erasing failed`): per "cancellare"
  `userdata`, `metadata` o `misc` si **flasha un'immagine** (zeri) al loro posto.
- **`misc` contiene il comando di boot**: se ci resta `boot-fastboot` (scritto da `reboot-fastboot`),
  il tablet riparte sempre in fastboot e non prova nemmeno ad avviare Android. Per questo va azzerata.
- **`--disable-verity` e `--disable-verification` servono entrambi**, e su **tutte e tre** le vbmeta:
  patchare solo la `vbmeta` principale non cambia niente (verificato: `veritymode` resta `enforcing`).
- **La firma della `vbmeta` non torna più** dopo la patch. Con il bootloader sbloccato AVB tollera e
  applica i flag: è il trucco standard delle GSI.
- **Android 14 (LineageOS 21) non parte** su questo vendor: bootloop, anche con AVB disattivato.
  Usa la 20 (Android 13).

## Se il tablet resta sul logo

1. Bootloop dopo il flash → quasi sempre manca un pezzo: `product` non ricreata, o `misc` non
   ripulita, o GSI sbagliata (A14).
2. Per vedere cosa dice il bootloader prima di uscire: leggi `uboot_log` (4 MB) con
   `spd_dump ... read_part uboot_log 0 0x400000 uboot_log.bin` e cercaci
   `androidboot.veritymode` e `enter mode`.
3. Per tornare indietro: [`05-recovery.md`](05-recovery.md).
