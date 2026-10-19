#!/usr/bin/env bash
# Blackview Tab 8 (SC9863A) - LineageOS 20 installer
# License: MIT.  Unlock method: TomKing062, CVE-2022-38694.
#
# Usage:
#   ./install.sh check      tools, permissions, device and firmware
#   ./install.sh unlock     unlock the bootloader (physical key combos required)
#   ./install.sh flash      install LineageOS 20 (GSI)
#   ./install.sh wipe       erase userdata+metadata from download mode
#   ./install.sh verify     read the bootloader state
#   ./install.sh restore    write back the original bootloaders you saved
#
# Options:
#   --dry-run        print the commands without running them
#   --gsi <file>     use a local GSI image instead of downloading it
#   -y               do not ask for confirmation

set -uo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
KIT="$REPO/artifacts/unlock-kit"
BKP="$REPO/backups"
GSI_URL="https://sourceforge.net/projects/andyyan-gsi/files/lineage-20-td/lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img.gz/download"
GSI_NAME="lineage-20.0-20251021-UNOFFICIAL-arm64_bvN-vndklite.img"
GSI_SHA="3b5ad7fc32bc59321a936f001d427602bc6942dbe4338238618f8d916375ef6e"
FW="Tab8_EEA_P30_V1.0_20211112V11"

SPD_DUMP="${SPD_DUMP:-$(command -v spd_dump 2>/dev/null || true)}"
if [ -z "$SPD_DUMP" ]; then
	for c in "$REPO/spreadtrum_flash/spd_dump" "$REPO/../spreadtrum_flash/spd_dump" \
	         "$HOME/CVE-2022-38694_unlock_bootloader/spreadtrum_flash/spd_dump"; do
		[ -x "$c" ] && { SPD_DUMP="$c"; break; }
	done
fi

# some binaries live in /sbin, which is not always in a user's PATH
have() {
	command -v "$1" >/dev/null 2>&1 && return 0
	for d in /sbin /usr/sbin /usr/local/bin; do [ -x "$d/$1" ] && return 0; done
	return 1
}
path_of() {
	command -v "$1" 2>/dev/null || { for d in /sbin /usr/sbin /usr/local/bin; do [ -x "$d/$1" ] && echo "$d/$1" && return; done; }
}

DRY=0; YES=0; GSI_LOCAL=""

msg()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  xx\033[0m %s\n' "$*" >&2; exit 1; }

run() {
	[ "$DRY" = 1 ] && { printf '    [dry-run] %s\n' "$*"; return 0; }
	"$@"
}

ask() {
	[ "$YES" = 1 ] && return 0
	printf '\n%s\n  Enter to continue, Ctrl-C to stop. ' "$*"
	read -r _
}

# only one program at a time may talk to the tablet
exclusive() {
	run sudo pkill -x spd_dump 2>/dev/null || true
	run adb kill-server 2>/dev/null || true
	sleep 1
}

spd() { exclusive; run sudo "$SPD_DUMP" --wait 300 "$@"; }

# ---------------------------------------------------------------- check
cmd_check() {
	msg "1/5 tools"
	local missing=()
	for t in adb fastboot unzip sha256sum mkfs.ext4 curl; do
		have "$t" || missing+=("$t")
	done
	MKFS="$(path_of mkfs.ext4)"
	[ -n "${SPD_DUMP:-}" ] && [ -x "$SPD_DUMP" ] || missing+=("spd_dump (see docs/01-preparation.md)")
	[ ${#missing[@]} -eq 0 ] && ok "all present" || die "missing: ${missing[*]}"
	ok "spd_dump: $SPD_DUMP"

	msg "2/5 unlock kit"
	local need=(fdl1-dl.bin fdl2-dl.bin fdl2-cboot.bin spl-unlock.bin misc-wipe.bin vbmeta-sign.img vbmeta_system.img vbmeta_vendor.img)
	for f in "${need[@]}"; do
		[ -f "$KIT/$f" ] || die "missing $KIT/$f (extract unlock-kit.tar.gz from the Releases)"
	done
	ok "kit complete in $KIT"

	msg "3/5 device reachable"
	adb start-server >/dev/null 2>&1
	if ! adb devices | grep -qw device; then
		warn "adb does not see the tablet: power it on and enable USB debugging"
		warn "(after unlocking, LineageOS exposes no serial: you need VID-based udev rules)"
		return 1
	fi
	ok "device: $(adb devices | sed -n '2p' | tr -s '\t' ' ')"

	msg "4/5 firmware"
	local fw; fw="$(adb shell getprop ro.fota.version 2>/dev/null | tr -d '\r')"
	[ -n "$fw" ] && ok "ro.fota.version: $fw"
	case "$fw" in
		"$FW"*) ok "firmware supported" ;;
		"") warn "cannot read ro.fota.version (not stock? already unlocked?)" ;;
		*) die "UNSUPPORTED FIRMWARE (expected ${FW}*). Stop here: the unlock artifacts are firmware-specific." ;;
	esac

	msg "5/5 files to download"
	[ -f "$REPO/$GSI_NAME" ] && ok "GSI present" || warn "GSI missing: it will be downloaded (~1 GB)"
	if [ -n "${PAC_FILE:-}" ] && [ -f "${PAC_FILE:-}" ]; then ok "pac: $PAC_FILE"; else
		warn "no pac: only needed for recovery (see docs/05-recovery.md)"; fi
}

# --------------------------------------------------------------- unlock
cmd_unlock() {
	[ -x "${SPD_DUMP:-}" ] || die "spd_dump not found (set SPD_DUMP=...)"
	mkdir -p "$BKP"
	msg "STEP 1/4 - dump YOUR bootloaders, unlock, non-verifying uboot"
	cat <<'EOT'
  The tablet must be in DOWNLOAD MODE:
    1. cable unplugged, tablet powered off
    2. hold VOL- and plug the cable, keep holding ~10 s
    3. the screen stays black
EOT
	ask "When ready, press Enter and do the key combo right away."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		path "$BKP" blk_size 0x8000 r splloader r uboot e splloader e splloader_bak \
		w uboot "$KIT/fdl2-cboot.bin" reset \
		|| die "failed. Run ./install.sh unlock again (and check the FAQ)."
	# dumped file names may vary: normalise
	for n in splloader uboot; do
		if [ ! -f "$BKP/$n" ] && [ -f "$BKP/$n.bin" ]; then cp "$BKP/$n.bin" "$BKP/$n"; fi
	done
	[ -f "$BKP/splloader" ] && [ -f "$BKP/uboot" ] || warn "no dumps in $BKP: do NOT use ./install.sh restore"
	ok "original bootloaders in $BKP"

	msg "STEP 2/4 - the unlock (patched SPL)"
	warn "This command LOOKS like it fails (usb_recv TIMEOUT). That is the sign it worked."
	ask "Do the download-mode combo again, then press Enter."
	spd exec_addr 0x4ee8 fdl "$KIT/spl-unlock.bin" 0x5000 || warn "timeout expected"

	msg "STEP 3/4 - unlock verification"
	ask "Download-mode combo, then press Enter."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		path "$BKP" blk_size 0x8000 read_part miscdata 8192 64 m_after.bin reset || true
	if [ -f "$BKP/m_after.bin" ] && tr -d '\000' < "$BKP/m_after.bin" | grep -q .; then
		ok "miscdata holds the unlock data"
	else
		die "miscdata is still empty: not unlocked. Repeat step 2."
	fi

	msg "STEP 4/4 - AVB disabled (patch YOUR trustos) + restore bootloaders"
	ask "Download-mode combo, then press Enter."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		blk_size 0x8000 dis_avb reset || die "dis_avb failed"
	if [ -f "$BKP/splloader" ] && [ -f "$BKP/uboot" ]; then
		ask "Last combo: restoring your original bootloaders."
		spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
			w splloader "$BKP/splloader" w uboot "$BKP/uboot" reset || warn "restore failed"
	fi
	msg "Unlock done. The tablet boots again now (on stock, if you have not flashed the GSI yet)."
}

# ---------------------------------------------------------------- flash
cmd_flash() {
	msg "1/5 GSI"
	if [ -n "$GSI_LOCAL" ]; then GSI_IMG="$GSI_LOCAL"; else
		if [ ! -f "$REPO/$GSI_NAME" ]; then
			msg "downloading the GSI (~1 GB)"
			curl -L --fail -o "$REPO/gsi.img.gz.part" "$GSI_URL" || die "download failed"
			gunzip -f "$REPO/gsi.img.gz.part" || die "corrupt gz"
			mv "$REPO/gsi.img" "$REPO/$GSI_NAME"
		fi
		GSI_IMG="$REPO/$GSI_NAME"
	fi
	echo "    expected sha256: $GSI_SHA"
	local got; got="$(sha256sum "$GSI_IMG" | cut -d' ' -f1)"
	[ "$got" = "$GSI_SHA" ] && ok "sha256 verified" || die "sha256 MISMATCH ($got): download it again"

	msg "2/5 fastbootd"
	run adb reboot fastboot; sleep 12
	fb() { timeout 1200 fastboot "$@"; }
	fb devices | grep -q fastboot || die "the tablet is not in fastbootd"
	[ "$(fb getvar is-userspace 2>&1 | grep -c 'yes')" = 1 ] || warn "is-userspace is not 'yes': this may be normal fastboot"
	ok "fastbootd ready"

	msg "3/5 logical partitions"
	ask "Deleting 'product' (space for the GSI; only revertible by reflashing stock)."
	run fb delete-logical-partition product
	ask "Writing the GSI into 'system' (~2 minutes, do not unplug)."
	run fb flash system "$GSI_IMG" || die "system flash failed"

	msg "4/5 AVB: three vbmeta images with verification disabled"
	for v in vbmeta vbmeta_system vbmeta_vendor; do
		run fb --disable-verity --disable-verification flash "$v" "$KIT/$v.img" || warn "$v flash failed"
	done

	msg "5/5 product and misc"
	dd if=/dev/zero of="$REPO/product-empty.img" bs=1M count=64 2>/dev/null
	run "$MKFS" -q -F -L product "$REPO/product-empty.img"
	run fb create-logical-partition product 0x4000000 || warn "product already exists?"
	run fb flash product "$REPO/product-empty.img" || warn "product flash failed"
	dd if=/dev/zero of="$REPO/misc-zero.img" bs=1M count=1 2>/dev/null
	run fb flash misc "$REPO/misc-zero.img" || warn "misc flash failed"

	msg "rebooting"
	run fb reboot
	cat <<'EOT'

  First boot: if it stays on the logo, the data wipe is missing.
    - from recovery: "Wipe data/factory reset"
    - or: same download mode, then ./install.sh wipe
EOT
}

# ----------------------------------------------------------------- wipe
cmd_wipe() {
	[ -x "${SPD_DUMP:-}" ] || die "spd_dump not found"
	msg "wiping userdata and metadata (from download mode)"
	ask "Download-mode combo, then press Enter."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		e userdata e metadata reset || die "wipe failed"
	ok "done: Android recreates the data on next boot"
}

# --------------------------------------------------------------- verify
cmd_verify() {
	adb devices | grep -qw device || { warn "adb does not see the tablet"; return 1; }
	for p in ro.boot.flash.locked ro.boot.verifiedbootstate ro.boot.vbmeta.device_state ro.build.version.release; do
		printf '  %-32s %s\n' "$p" "$(adb shell getprop "$p" 2>/dev/null | tr -d '\r')"
	done
}

# -------------------------------------------------------------- restore
cmd_restore() {
	[ -f "$BKP/splloader" ] || die "missing $BKP/splloader"
	[ -f "$BKP/uboot" ]    || die "missing $BKP/uboot"
	msg "restoring the original bootloaders"
	ask "Download-mode combo, then press Enter."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		w splloader "$BKP/splloader" w uboot "$BKP/uboot" reset || die "restore failed"
	ok "done"
}

# ----------------------------------------------------------------- main
CMD="${1:-}"; shift || true
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY=1 ;;
		-y) YES=1 ;;
		--gsi) GSI_LOCAL="$2"; shift ;;
		*) die "unknown option: $1" ;;
	esac
	shift
done

case "$CMD" in
	check)   cmd_check ;;
	unlock)  cmd_unlock ;;
	flash)   cmd_flash ;;
	wipe)    cmd_wipe ;;
	verify)  cmd_verify ;;
	restore) cmd_restore ;;
	*) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
