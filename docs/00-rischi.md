# Rischi, prima di tutto

Questa procedura **sblocca il bootloader** e **scrive nelle partizioni del bootloader**. Non è
reversibile con un click, e non è per tutti.

## Cosa si perde, per certo

- **Tutti i dati del tablet** (foto, app, account). Lo sblocco e il passaggio a una GSI azzerano
  `userdata`. Non c'è modo di evitarlo.
- **Il sistema stock Blackview e la garanzia** (se ne resta un pezzo).
- L'**avviso "unlock"** all'accensione: resta per sempre, finché il bootloader è sbloccato.

## Cosa si rischia, se qualcosa va storto

| Rischio | Quanto è grave | Come si recupera |
|---|---|---|
| Bootloop dopo il flash | fastidioso | si riflashano i bootloader dal kit, o si rimette lo stock |
| Scrittura sbagliata di `splloader`/`uboot` | **grave**: il tablet non si accende più normalmente | solo entrando in **download mode** (combo Vol‑ + cavo) e riscrivendoli |
| Tablet che non entra in download mode | **molto grave** | serve aprire la scocca e **scollegare la batteria**; se il BootROM è compromesso, il recupero è incerto |

Il BootROM **non** viene toccato da questa procedura (l'exploit gira in RAM), quindi il download mode
resta sempre disponibile: è la ragione per cui il recupero è realistico.

## Le regole che non si saltano

1. **Il firmware stock in mano, prima di iniziare.** Il `.pac` è la rete di sicurezza: se il tablet
   non si avvia, da lì si riscrive tutto. L'installer lo scarica (o te lo chiede) nel passo `check`.
   Senza, non procedere.
2. **Firmware giusto.** Gli artefatti di sblocco (`spl-unlock.bin`, `fdl2-cboot.bin`) derivano dal
   **tuo** `splloader` e dagli FDL del **tuo** firmware. Su un firmware diverso sono **veleno**.
   L'installer verifica `ro.fota.version` e si ferma se non combacia. Non aggirare quel controllo.
3. **Un solo programma per volta che parla col tablet.** L'interfaccia USB è una sola: due
   `spd_dump` insieme fanno fallire tutto con `LIBUSB_ERROR_BUSY`. Anche `adb` va fermato prima.
4. **Non staccare il cavo durante le scritture.** Se succede, il tablet resta in download mode:
   si riprende da lì, non è finita.
5. **Batteria carica** (almeno il 50%) prima di iniziare.

## Cosa NON è coperto

- Windows e macOS. Solo Linux.
- Tablet con firmware diverso da `Tab8_EEA_P30_V1.0_20211112V11` (verificato dall'installer).
- Aggiornamenti OTA di LineageOS: con una GSI ogni aggiornamento è un riflash.
- Camera e modem LTE: non verificati (potrebbero non funzionare, il vendor resta quello del 2021).

Se qualcosa qui non ti è chiaro, **fermati**: un tablet che non si accende è un problema molto più
grande di un tablet con Android 10 stock.
