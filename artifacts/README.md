# artifacts/ — il kit di sblocco

Qui va estratto `unlock-kit.tar.gz`, scaricato dalle
[Releases](https://github.com/Elkon/blackview-tab8-lineageos/releases).

Contenuto (`artifacts/unlock-kit/`):

| file | cos'è | da dove viene |
|---|---|---|
| `fdl1-dl.bin` | FDL1 (primo stadio di download) con la verifica di `data_exec` neutralizzata | `gen_fdl1-dl` applicato all'FDL1 estratto dal `.pac` |
| `fdl2-dl.bin` | FDL2 (secondo stadio) che permette di **scrivere** le partizioni protette | pacchetto `sc9863a_Itel_Vision_3` di TomKing062 |
| `fdl2-cboot.bin` | uboot con `do_cboot()` senza verifica: è quello che si scrive in `uboot` | idem |
| `spl-unlock.bin` | il nostro `splloader` con il controllo di firma messo a `NOP` | `gen_spl-unlock-legacy` sul `splloader` del Tab 8 (build EEA 2021) |
| `misc-wipe.bin` | comando di wipe per la partizione `misc` | pacchetto Itel |
| `vbmeta-sign.img`, `vbmeta_system.img`, `vbmeta_vendor.img` | le tre vbmeta stock, da patchare con `--disable-verity --disable-verification` al momento del flash | estratte dal `.pac` |

**Base degli FDL** (lette dall'XML del `.pac`, e confermate dalla
[tabella ufficiale](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
per `sc9863a`): FDL1 → `0x5000`, FDL2 → `0x9EFFFE00`.

## Perché è specifico di un firmware

`spl-unlock.bin` è il **vostro** `splloader` patchato: su un tablet con firmware diverso
(NEU/ROW, o con OTA Android 11) è un'immagine incompatibile. Per questo l'installer confronta
`ro.fota.version` con `Tab8_EEA_P30_V1.0_20211112V11` e si ferma se non combacia.

## Come rigenerarlo da soli (nessuna fiducia necessaria)

Il kit è riproducibile dai propri file, senza scaricare binari da noi:

```
# 1. gli FDL e le vbmeta dal firmware stock (.pac)
unpac -d out extract DK_....pac fdl1-sign.bin fdl2-sign.bin '*.xml' vbmeta-sign.img vbmeta_system.img vbmeta_vendor.img
python3 - <<'PY'   # basi FDL dall'XML
import re;t=open('out/s9863a1h10.xml',encoding='utf8').read()
print([m for m in re.findall(r'<Base>(0x[0-9A-Fa-f]+)</Base>',t)][:2])
PY

# 2. fdl1-dl dal proprio FDL1
gcc gen_fdl1-dl.c -o gen_fdl1-dl && cp out/fdl1-sign.bin fdl1-dl.bin && ./gen_fdl1-dl fdl1-dl.bin

# 3. fdl2-dl / fdl2-cboot: prendili dal pacchetto Itel Vision 3 nelle Releases di
#    TomKing062/CVE-2022-38694_unlock_bootloader (sono specifici del *SoC*, non del modello)

# 4. spl-unlock dal PROPRIO splloader (dumpato dal tablet in download mode con `r splloader`)
gcc gen_spl-unlock-legacy.c -o gen_spl-unlock-legacy
cp splloader.bin spl.bin && ./gen_spl-unlock-legacy spl.bin     # -> spl-unlock.bin (attesi ~73 NOP)
```

Il `.pac` non è incluso nel repo (3,6 GB, firmware di proprietà Blackview): è nelle Releases come
pacchetto di recupero, oppure si cerca altrove.
