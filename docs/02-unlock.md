# Sblocco del bootloader (BootROM, CVE-2022-38694)

Il fastboot di questo tablet **non implementa lo sblocco**: `fastboot flashing unlock` risponde
`Not implemet.` e `fastboot oem unlock` risponde `unknown cmd.`. L'unica via è il **BootROM**, con
l'exploit [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) di
TomKing062: si carica in RAM un piccolo payload che aggira la verifica di firma del BootROM, si
caricano FDL firmati presi dal firmware, e da lì si scrive nelle partizioni del bootloader.

**Tutto il merito del metodo è suo.** Qui c'è solo la ricetta per il Tab 8.

## Cosa fa l'exploit, in breve

Unisoc verifica la firma di ciò che il PC gli manda nel BootROM. Il payload
(`custom_exec_no_verify_4ee8.bin`, 128 byte) sfrutta un difetto che permette di eseguire codice con i
privilegi del BootROM: da lì i controlli di firma non valgono più, e si può caricare il proprio
`fdl1`/`fdl2` e scrivere `splloader`, `uboot`, `trustos`.

## La sequenza (quella automatizzata da `./install.sh unlock`)

Si entra in **download mode**: tablet spento, **Vol‑ premuto**, inserisci il cavo, tieni ~10 s. Il
tablet compare come `1782:4d00` e ci resta ~30 secondi: per questo l'installer resta in attesa prima
(`spd_dump --wait`) e poi ti chiede la combo.

### 1. Dump dei bootloader e sblocco

```
spd_dump --wait 300 exec_addr 0x4ee8 \
  fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 r splloader r uboot \
  e splloader e splloader_bak \
  w uboot fdl2-cboot.bin reset
```

- `r splloader r uboot` → **salva i tuoi** bootloader originali (servono al ripristino: non usare
  quelli di altri).
- `e splloader e splloader_bak` → cancella lo stadio che il BootROM caricherebbe da flash. Da qui il
  tablet non si avvia più normalmente: **è previsto**.
- `w uboot fdl2-cboot.bin` → mette un `uboot` che non verifica le firme degli stadi successivi.

### 2. L'unlock vero e proprio

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl spl-unlock.bin 0x5000
```

`spl-unlock.bin` è **il tuo** `splloader` con il controllo di firma neutralizzato (73 istruzioni
`NOP`): lo genera `gen_spl-unlock-legacy` dal dump del passo 1.

> ⚠️ **Questo comando "fallisce" ed è il segnale che ha funzionato.** L'SPL patchato non resta in
> attesa del PC (niente risposta al `CHECK_BAUD`: vedrai `usb_recv failed` e `TIMEOUT`): tira dritto,
> carica l'`uboot` patchato e quello scrive i dati di sblocco. La prova vera è il passo 3.

### 3. Verifica

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 read_part miscdata 8192 64 m_after.bin reset
```

- **64 byte tutti a zero** → ancora bloccato: ripeti il passo 2.
- **32 byte + 16 + 16** (hash) → **sbloccato** (è il "legal unlock data" che il bootloader scrive in
  `miscdata` a `0x2000`).

### 4. AVB fuori dai piedi

Il bootloader continuerebbe a pretendere immagini firmate dal vendor. `dis_avb` patcha il **tuo**
`trustos` (dove Unisoc fa la verifica vera, via TEE) e lo riscrive:

```
spd_dump --wait 300 exec_addr 0x4ee8 fdl fdl1-dl.bin 0x5000 fdl fdl2-dl.bin 0x9EFFFE00 exec \
  blk_size 0x8000 dis_avb reset
```

### 5. Ripristino dei bootloader originali

Si rimettono `splloader` e `uboot` salvati al passo 1 (lo sblocco è già registrato in `miscdata`):

```
spd_dump ... w splloader <tuo splloader> w uboot <tuo uboot> reset
```

Da qui il tablet riparte — **con Android stock se non hai ancora flashato la GSI**, e con il
bootloader sbloccato.

## Firmware: perché conta

`spl-unlock.bin`, `fdl2-cboot.bin` e `fdl1-dl.bin` sono derivati da **quel** firmware. Su un Tab 8
con firmware diverso (NEU 2020, ROW, OTA A11) sono immagini incompatibili: il tablet non si avvia e
serve il loro `.pac` per tornare indietro. L'installer verifica `ro.fota.version` e si ferma se non
combacia — **non aggirare quel controllo**.

## Riferimenti

- [TomKing062/CVE-2022-38694_unlock_bootloader](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) — tool, payload, wiki
- [Wiki — Unlock](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/Unlock) ·
  [SupportList](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/SupportList) ·
  [AddSupportToModel](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel)
- [NCC Group — There's another hole in your SoC](https://research.nccgroup.com/2022/09/02/theres-another-hole-in-your-soc-unisoc-rom-vulnerabilities/) — l'analisi del difetto
