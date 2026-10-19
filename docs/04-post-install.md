# After installing

## What works

On our unit: wifi, touch, audio, auto-rotation, brightness. Camera and the LTE modem were not tried.

The bootloader state, from adb:

    adb shell getprop ro.boot.flash.locked         # 0
    adb shell getprop ro.boot.verifiedbootstate    # orange
    adb shell getprop ro.boot.vbmeta.device_state  # unlocked

## Making it less sluggish

The PowerVR GE8322 is the weak part, and it is compositing a 1200x1920 panel. Three things help, all
of them revertible.

Fewer pixels is the big one:

    adb shell wm size 800x1280
    adb shell wm density 160

Same ratio, 1.5x fewer pixels, same physical size of the interface. `wm size reset` and
`wm density reset` put it back.

The panel reports itself as portrait, so the order is width by height. Setting a landscape size makes
rotation come out inverted, which is confusing until you notice.

Shorter animations:

    adb shell settings put global window_animation_scale 0.5
    adb shell settings put global transition_animation_scale 0.5
    adb shell settings put global animator_duration_scale 0.5

Compile everything ahead of time, once, with the tablet idle and plugged in. Takes half an hour and
makes it hot:

    adb shell cmd package compile -m speed -f -a

`debug.hwui.renderer=skiagl` does nothing here. The system already runs Skia on OpenGL, check with
`dumpsys gfxinfo`. The Vulkan backend is slower on this GPU.

## Battery

There is no charge limit. `constant_charge_current` and `input_current_limit` are writable in
appearance but Unisoc's `charger-manager` puts the policy value back immediately, and
`constant_charge_voltage` is read-only even for root. The BATFET bypass the BQ2560x offers lives
behind i2c registers that are not exposed, and a wrong write there leaves a tablet that will not
charge.

When it is plugged in and full the system runs from USB and the battery is not cycled. It just sits at
100%, and heat is what ages it. For a tablet mounted on a wall, the workable options are keeping it
cool, or switching the supply with a smart plug between about 40% and 80%:

    adb shell cat /sys/class/power_supply/battery/capacity

## Root

Off by default. Settings, System, Developer options, Rooted debugging, then `adb root`. It is also
what you need to `dd` a raw partition, for example a `super` backup.
