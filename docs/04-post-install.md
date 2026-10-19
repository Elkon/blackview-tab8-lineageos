# Dopo l'installazione: collaudo e messa a punto

## Collaudo

Su hardware reale (Tab 8, build EEA 2021) funzionano:

| | |
|---|---|
| Wifi | ✅ |
| Touch | ✅ |
| Audio | ✅ |
| Rotazione automatica | ✅ |
| Luminosità | ✅ |
| Camera | non verificata |
| Modem LTE | non verificato |

Verifica veloce dello stato del bootloader:

```
adb shell getprop ro.boot.flash.locked        # deve essere 0
adb shell getprop ro.boot.verifiedbootstate   # orange = sbloccato
adb shell getprop ro.boot.vbmeta.device_state # unlocked
```

## Messa a punto (tab 8 = GPU debole, 4 GB RAM)

Il collo di bottiglia è la **PowerVR GE8322** che compone un pannello 1200×1920. Tre interventi, in
ordine di resa, tutti reversibili:

### 1. Ridurre i pixel da comporre (il guadagno più grande)

```
adb shell wm size 800x1280
adb shell wm density 160
```

Stesso rapporto del pannello (1,5× meno pixel), stessa dimensione fisica dell'interfaccia
(240/1,5 = 160 dpi). Si annulla con `wm size reset && wm density reset`.

> Attenzione all'ordine `larghezza x altezza`: il pannello si dichiara **verticale** (1200×1920). Se
> imposti una misura orizzontale la rotazione risulta invertita.

### 2. Animazioni più corte

```
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

### 3. Compilare in anticipo le app (AOT)

```
adb shell cmd package compile -m speed -f -a
```

Richiede 30–60 minuti e surriscalda: va lanciato una volta, con il tablet fermo e attaccato. Dopo, le
app si aprono senza il costo della compilazione a runtime.

### Cosa non serve

- **`debug.hwui.renderer=skiagl`**: il sistema usa **già** Skia su OpenGL
  (`dumpsys gfxinfo` → `Pipeline=Skia (OpenGL)`). Cambiarlo non fa nulla; `skiavk` su questa GPU è
  più lento.

## Batteria

Nessun controllo della carica da software: i nodi
`/sys/class/power_supply/battery/{constant_charge_current,input_current_limit,charge_control_limit}`
sono `-rw-` ma le scritture vengono **riportate al valore di politica** dal `charger-manager` di
Unisoc, e `constant_charge_voltage` è **read-only** (`-r--r--r--`).

Conseguenza per un uso fisso (dashboard a muro): a batteria piena il sistema è alimentato da USB e la
batteria non viene ciclata, ma resta al 100% — e il calore è il fattore di usura principale. Le opzioni
sono tenere il tablet fresco, o ciclare l'alimentazione con una presa smart fra ~40% e ~80%
(`adb shell cat /sys/class/power_supply/battery/capacity` è leggibile).

## Root

LineageOS lo tiene spento per default: Impostazioni → Sistema → Opzioni sviluppatore →
**Debug root** ("Rooted debugging"), poi `adb root`. Serve anche per `dd` delle partizioni
(es. il backup di `super`).
