# Tornare indietro

Ci sono tre livelli di "tornare indietro". Scegli in base a cosa hai rotto.

## A. Il tablet è in bootloop, ma entra in download mode

**Caso più comune.** Non serve il firmware stock: bastano i bootloader originali, che l'installer
salva prima di toccarli (`backup/splloader.bin`, `backup/uboot.bin`, `backup/miscdata.bin`).

```
./install.sh restore
```

Rimette `splloader`, `uboot` e `miscdata` originali. Se il sistema (la GSI) è sano, riparte.

Se invece hai flashato una GSI sbagliata (per esempio Android 14) e resta in loop, il ripristino dei
bootloader **non basta**: bisogna riflashare la `system` giusta
([`03-flash-gsi.md`](03-flash-gsi.md)) oppure tornare allo stock (punto B).

## B. Tornare ad Android 10 stock (Blackview)

Serve il `.pac` (scaricabile dalle Releases di questo repo). Da download mode, con `spd_dump`:

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

Le immagini `*-stock` si estraggono dal `.pac` con `unpac` (incluso in `spreadtrum_flash`):

```
./unpac list DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac
./unpac -d extracted extract DK_....pac super.img u-boot-spl-16k-sign.bin u-boot-sign.bin tos-sign.bin
```

> Il `.pac` disponibile è **NEU 2020**: otterrai un Android 10 funzionante, ma non la build EEA 2021
> che aveva il tablet di fabbrica (quella non è mai stata dumpata). Il tablet torna comunque
> completamente usabile, e resta **sbloccato**.

In alternativa, la via ufficiale: `ResearchDownload` (Windows) o `Factory Download` con lo stesso
`.pac`, che riscrive tutto — è la strada che usano le guide per "unbrick".

## C. Il tablet non entra in download mode

**Il caso brutto.** Se tenere premuto **Vol‑** mentre inserisci il cavo non fa comparire
`1782:4d00`:

1. **Scollega il cavo** (in modalità carica il tablet non è visibile al PC) e forza lo spegnimento
   con **Power 15–20 s**.
2. Riprova tenendo premuto **Vol‑** *prima* di inserire il cavo, e continua a tenerlo ~10 s.
3. Prova anche **Vol+**, o **Power + Vol‑** insieme.
4. Se niente funziona: **apri la scocca e scollega la batteria** per qualche secondo, poi ricollega e
   riprova. Diverse persone hanno recuperato così tablet dati per morti (a volte era solo la batteria
   completamente scarica).

## Cosa NON fare

- Non scrivere `splloader`/`uboot` con immagini prese da **un altro** tablet o da un altro firmware:
  è il modo più rapido per trasformare un bootloop in un fermacarte.
- Non rimuovere la batteria con il cavo collegato.
- Non interrompere una scrittura di `super` (4 GB): se si interrompe, il tablet resta in download mode
  e si ripete — non è definitivo, ma serve il `.pac`.
