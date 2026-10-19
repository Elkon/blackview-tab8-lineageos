# FAQ — le cinque trappole

Sono i punti in cui ci si blocca davvero. Li abbiamo pagati uno per uno.

---

## 1. `spd_dump` resta per sempre su "Waiting for dl_diag connection"

**Anche se il tablet è collegato e il nodo USB ha i permessi giusti.**

Non è il tablet: è che `spd_dump` si appoggia all'**hotplug di libusb**, che su Linux ascolta gli
eventi di **udevd**. Se `udevd` non gira (container, sistemi minimali, `/sys` read-only) il programma
resta in attesa per sempre.

Verifica:

```
systemctl is-active systemd-udevd
```

Se non è attivo:

```
sudo systemctl start systemd-udevd
# oppure, se systemd lo salta per una condizione:
sudo nohup /lib/systemd/systemd-udevd &
```

Sintomo alternativo, che indica la stessa famiglia di problemi: `libusb_claim_interface failed :
LIBUSB_ERROR_BUSY`.

---

## 2. `LIBUSB_ERROR_BUSY` al claim dell'interfaccia

L'interfaccia USB del tablet è **una sola**: o la tiene un altro programma, o la tiene il tool stesso.

- **Un altro programma**: `sudo pkill -x spd_dump` e ferma anche `adb` (`adb kill-server`) prima di
  lanciare `spd_dump`. Due `spd_dump` insieme non funzionano *mai*.
- **Il tool stesso**: alcune versioni aprono il device due volte e il secondo `claim` sbatte contro il
  primo. Se succede, aggiorna `spd_dump` all'ultima versione del fork di TomKing062.

---

## 3. `install.sh unlock` dice che il passo dell'SPL è fallito (ma ha funzionato)

L'output contiene:

```
usb_recv failed : LIBUSB_ERROR_TIMEOUT
CHECK_BAUD FAIL
usb_send failed : LIBUSB_ERROR_TIMEOUT
```

**È il comportamento atteso.** `spl-unlock.bin` non resta in attesa del PC: esegue, carica l'`uboot`
patchato e quello scrive i dati di sblocco. Il tool non riceve risposta e sembra morto.

La prova vera è la verifica di `miscdata`:

```
spd_dump ... read_part miscdata 8192 64 m_after.bin
```

- 64 byte **tutti a zero** → non è sbloccato, ripeti il passo.
- 32 byte + 16 + 16 → **sbloccato**.

Non "correggere" quel timeout: non è un errore.

---

## 4. `fastboot erase` risponde `Erasing failed`

Questo bootloader non implementa `erase` per `userdata`, `metadata` e `misc`. Si aggira **flashendo
un'immagine** di zeri al loro posto:

```
# misc (1 MB) — serve per cancellare il comando "boot-fastboot" e far ripartire Android
dd if=/dev/zero of=misc-zero.img bs=1M count=1
fastboot flash misc misc-zero.img
```

Per `userdata` il wipe si fa dalla recovery (Wipe data/factory reset) oppure dal tool in download mode
(scrive il comando in `misc` e cancella `metadata`).

---

## 5. Dopo il flash resta sul logo Blackview (bootloop)

In ordine di probabilità:

1. **`misc` contiene ancora `boot-fastboot`** → il tablet non prova nemmeno ad avviare Android.
   Azzera `misc` (vedi punto 4).
2. **`product` non è stata ricreata** → la fstab del vendor la monta, e init non arriva in fondo.
   `fastboot create-logical-partition product 0x4000000` + `flash product` con un ext4 vuoto.
3. **GSI sbagliata**: **Android 14 non parte** su questo vendor. Serve la **20 (Android 13)**,
   `arm64_bvN-vndklite`. Con A14 il loop c'è anche con AVB completamente disattivato: non perdere
   giorni.
4. **Dati vecchi**: se non hai fatto il wipe, l'userdata di Android 10 non è montabile da Android 13.

Per capire *dove* si ferma, leggi il log del bootloader:

```
spd_dump ... read_part uboot_log 0 0x400000 uboot_log.bin
strings uboot_log.bin | grep -E "veritymode|enter mode|Error"
```

---

## Extra: `adb` non vede il tablet (o "no permissions")

- Il tablet in modalità **download** non è un device Android: `adb` non lo vede, è normale.
- Dopo l'installazione LineageOS **non espone il seriale** sulla USB: se avevi una regola udev legata al
  seriale, non scatta più. Usa le regole per VID (`1782` e `18d1`, vedi
  [`01-preparazione.md`](01-preparazione.md)).
- `user X is not in the plugdev group` è il messaggio generico di adb quando non riesce ad aprire il
  nodo: quasi sempre sono i permessi udev, non il gruppo.
