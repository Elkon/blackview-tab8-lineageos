# Preparazione

## 1. Strumenti sul PC (Debian/Ubuntu)

```
sudo apt install -y adb fastboot build-essential libusb-1.0-0-dev libxml2-dev pkg-config unzip e2fsprogs
```

Serve anche **`spd_dump`**, il programma che parla col BootROM. Non è in apt: si compila dal fork di
TomKing062 (che è quello che supporta il protocollo di questo SoC):

```
git clone --recursive https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader.git
cd CVE-2022-38694_unlock_bootloader/spreadtrum_flash && make
```

Il binario che serve è `spreadtrum_flash/spd_dump`. Metti il percorso in `SPD_DUMP` o lascialo in
`PATH`: l'installer lo cerca lì.

## 2. Permessi USB

Senza regole udev, `adb`, `fastboot` e `spd_dump` non possono aprire il tablet. Crea
`/etc/udev/rules.d/51-bvtab8.rules`:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666"
```

Poi:

```
sudo udevadm control --reload && sudo udevadm trigger --action=add --subsystem-match=usb
```

Il tablet comparirà con **due ID diversi a seconda della modalità** (è normale, non è un errore):

| modalità | VID:PID |
|---|---|
| download mode (BootROM/firmware download) | `1782:4d00` |
| Android / fastboot | `18d1:4ee8`, `18d1:4ee0` |

## 3. File da scaricare

L'installer li scarica da solo (`./install.sh check`), verificando gli sha256 di
[`CHECKSUMS.md`](../CHECKSUMS.md). Se preferisci farlo a mano:

| file | dove | perché |
|---|---|---|
| **GSI LineageOS 20** `lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img.gz` | [SourceForge — Andy Yan](https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/) | il sistema che si installa |
| **Firmware stock** `DK_SC9863A_P30_5G_10.0_Tab8_NEU_20200731_V1.0.pac.gz` (1,9 GB) | [GitHub Releases di questo repo](https://github.com/Elkon/blackview-tab8-lineageos/releases) | rete di sicurezza + FDL + `vbmeta`; si scompatta con `gunzip` (3,6 GB) |
| **Kit di sblocco** (`unlock-kit.tar.gz`) | [GitHub Releases di questo repo](https://github.com/Elkon/blackview-tab8-lineageos/releases) | i pezzi per sbloccare |

> Il `.pac` è **NEU 2020**, mentre il tablet monta la build **EEA 2021**: per la rete di sicurezza va
> bene (stessa board, `s9863a1h10`), ma se torni allo stock otterrai Android 10 NEU, non la build
> esatta EEA. Il dump del sistema stock esatto non è incluso: non lo abbiamo.

## 4. Verifica di partenza

Tablet acceso, debug USB attivo (Impostazioni → Info → tocca "Numero build" 7 volte → Opzioni
sviluppatore → Debug USB), poi:

```
./install.sh check
```

Controlla: strumenti, permessi USB, device raggiungibile, **firmware supportato**.
Se il firmware non combacia, l'installer si ferma: è la protezione più importante di tutte
(gli artefatti di sblocco sono per-firmware).
