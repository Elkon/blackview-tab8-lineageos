# After installing: hardware check and tuning

## Hardware check

On real hardware (Tab 8, EEA 2021 build) the following work:

| | |
|---|---|
| Wifi | ✅ |
| Touch | ✅ |
| Audio | ✅ |
| Auto-rotation | ✅ |
| Brightness | ✅ |
| Camera | untested |
| LTE modem | untested |

Quick bootloader state check:

```
adb shell getprop ro.boot.flash.locked        # must be 0
adb shell getprop ro.boot.verifiedbootstate   # orange = unlocked
adb shell getprop ro.boot.vbmeta.device_state # unlocked
```

## Tuning (weak GPU, 4 GB RAM)

The bottleneck is the **PowerVR GE8322** compositing a 1200×1920 panel. Three changes, in order of
impact, all reversible:

### 1. Compose fewer pixels (the biggest win)

```
adb shell wm size 800x1280
adb shell wm density 160
```

Same panel ratio (1.5× fewer pixels), same physical UI size (240/1.5 = 160 dpi). Revert with
`wm size reset && wm density reset`.

> Mind the `width x height` order: the panel reports itself as **portrait** (1200×1920). If you set a
> landscape size, rotation ends up inverted.

### 2. Shorter animations

```
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

### 3. Ahead-of-time compile the apps

```
adb shell cmd package compile -m speed -f -a
```

Takes 30–60 minutes and heats the tablet: run it once, idle and plugged in. Afterwards apps open
without the runtime compile cost.

### What does not help

- **`debug.hwui.renderer=skiagl`**: the system **already** uses Skia on OpenGL
  (`dumpsys gfxinfo` → `Pipeline=Skia (OpenGL)`). Changing it does nothing; `skiavk` is slower on this
  GPU.

## Battery

There is no software charge control: `/sys/class/power_supply/battery/{constant_charge_current,input_current_limit,charge_control_limit}`
are `-rw-` but writes are **reverted to the policy value** by Unisoc's `charger-manager`, and
`constant_charge_voltage` is **read-only** (`-r--r--r--`).

Consequence for a fixed installation (wall dashboard): at full charge the system runs from USB and the
battery is not cycled, but it stays at 100% — and heat is the main ageing factor. Options: keep it cool,
or cycle the power with a smart plug between ~40% and ~80%
(`adb shell cat /sys/class/power_supply/battery/capacity` is readable).

## Root

LineageOS disables it by default: Settings → System → Developer options → **Rooted debugging** ("Debug
root"), then `adb root`. You also need it for `dd` of raw partitions (e.g. a `super` backup).
