# LineageOS 20 sul Blackview Tab 8 (Unisoc SC9863A)

Guida e strumenti per installare **LineageOS 20 (Android 13)** su un **Blackview Tab 8**
(Unisoc SC9863A, 4/64 GB), un tablet del 2020 abbandonato dalla casa madre, **senza kernel source
né device tree**.

Il risultato, verificato su hardware reale: LineageOS 20 con **wifi, touch, audio, rotazione e
luminosità funzionanti**.

> ⚠️ **Leggi [`docs/00-rischi.md`](docs/00-rischi.md) prima di toccare qualsiasi cosa.**
> Si sblocca il bootloader (addio dati), si scrive nelle partizioni del bootloader e si cancella
> il sistema stock. Si può tornare indietro, ma solo con il firmware stock in mano.

## Come funziona, in tre righe

Il bootloader del Tab 8 **non si sblocca da fastboot** (`flashing unlock` risponde
`Not implemet.`): si sblocca dal **BootROM**, sfruttando [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
(il progetto di TomKing062, che ha fatto tutto il lavoro difficile). Poi si installa una **GSI**
(Generic System Image) di LineageOS al posto della `system` stock, e si disattiva AVB.

## Requisiti

- Un **PC Linux** (x86_64). Su Windows i driver SPRD e libusb si pestano i piedi: non è supportato.
- Il tablet con il **firmware EEA `Tab8_EEA_P30_V1.0_20211112V11`** (l'installer verifica e si
  rifiuta se non combacia: gli artefatti di sblocco sono **per-firmware**).
- Cavo USB **dati** (non solo carica).
- ~5 GB liberi sul PC.

## Installazione

```
git clone https://github.com/Elkon/blackview-tab8-lineageos.git
cd blackview-tab8-lineageos
./install.sh check      # verifica strumenti, device e firmware
./install.sh unlock     # sblocca il bootloader (richiede la combo fisica)
./install.sh flash      # installa LineageOS 20
```

Ogni passo spiega cosa sta per fare e si ferma se qualcosa non torna. `--dry-run` mostra i comandi
senza eseguirli.

## Cosa c'è nel repo

```
install.sh          il wizard (check / unlock / flash / verify / restore)
artifacts/          kit di sblocco per questo firmware (+ come rigenerarlo da soli)
docs/00-rischi.md   cosa si rompe, cosa è irreversibile, come si recupera
docs/01-preparazione.md  strumenti, permessi USB, file da scaricare
docs/02-unlock.md   la procedura di sblocco, passo per passo
docs/03-flash-gsi.md  fastbootd, partizioni dinamiche, vbmeta, wipe
docs/04-post-install.md  collaudo e messa a punto
docs/05-recovery.md  tornare allo stock
FAQ.md              le cinque trappole in cui si bloccano tutti
CHECKSUMS.md        sha256 di tutto ciò che si scarica
```

## Stato di supporto

| | |
|---|---|
| LineageOS | **20.0** (Android 13), GSI `arm64_bvN-vndklite` di [Andy Yan](https://sourceforge.net/projects/andyyan-gsi/) |
| Hardware | wifi, touch, audio, rotazione, luminosità ✅ — camera e modem LTE non verificati |
| Android 14 (LineageOS 21) | **non funziona** su questo vendor: bootloop. Non perdere giorni, vedi FAQ |
| Limiti noti | nessun controllo della carica da software (vedi `docs/04`) |

## Crediti

- **[TomKing062](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)** — il metodo di
  sblocco (CVE-2022-38694) e [`spd_dump`](https://github.com/TomKing062/spreadtrum_flash): senza il
  suo lavoro questo tablet sarebbe un fermacarte.
- **Andy Yan** — le GSI LineageOS TrebleDroid-based.
- La ricetta specifica per il Tab 8 (quali file, in che ordine, e le trappole) è verificata su
  hardware reale da questo repo.

Licenze: codice MIT, testi CC BY-SA 4.0. Vedi `LICENSE` e `LICENSE-docs`.
