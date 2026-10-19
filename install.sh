#!/usr/bin/env bash
# Blackview Tab 8 (SC9863A) - LineageOS 20 installer
# Licenza: MIT.  Metodo di sblocco: TomKing062, CVE-2022-38694.
#
# Uso:
#   ./install.sh check      verifica strumenti, permessi, device e firmware
#   ./install.sh unlock     sblocca il bootloader (comandi fisici richiesti)
#   ./install.sh flash      installa LineageOS 20 (GSI)
#   ./install.sh wipe       azzera userdata+metadata da download mode
#   ./install.sh verify     controlla lo stato del bootloader
#   ./install.sh restore    rimette i bootloader originali salvati
#
# Opzioni:
#   --dry-run        mostra i comandi senza eseguirli
#   --gsi <file>     usa una GSI locale invece di scaricarla
#   -y               non chiedere conferma

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

# alcuni binari stanno in /sbin, che non sempre e' nel PATH dell'utente
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
	if [ "$DRY" = 1 ]; then printf '    [dry-run] %s\n' "$*"; return 0; fi
	"$@"
}

ask() {
	[ "$YES" = 1 ] && return 0
	printf '\n%s\n  Invio per continuare, Ctrl-C per fermarsi. ' "$*"
	read -r _
}

# un solo programma per volta puo' parlare col tablet
exclusive() {
	run sudo pkill -x spd_dump 2>/dev/null || true
	run adb kill-server 2>/dev/null || true
	sleep 1
}

spd() { exclusive; run sudo "$SPD_DUMP" --wait 300 "$@"; }

# ---------------------------------------------------------------- check
cmd_check() {
	msg "1/5 strumenti"
	local missing=()
	for t in adb fastboot unzip sha256sum mkfs.ext4 curl; do
		have "$t" || missing+=("$t")
	done
	MKFS="$(path_of mkfs.ext4)"
	[ -n "${SPD_DUMP:-}" ] && [ -x "$SPD_DUMP" ] || missing+=("spd_dump (vedi docs/01-preparazione.md)")
	[ ${#missing[@]} -eq 0 ] && ok "tutti presenti" || die "manca: ${missing[*]}"
	ok "spd_dump: $SPD_DUMP"

	msg "2/5 kit di sblocco"
	local need=(fdl1-dl.bin fdl2-dl.bin fdl2-cboot.bin spl-unlock.bin misc-wipe.bin vbmeta-sign.img vbmeta_system.img vbmeta_vendor.img)
	for f in "${need[@]}"; do
		[ -f "$KIT/$f" ] || die "manca $KIT/$f (estrai unlock-kit.tar.gz dalle Releases)"
	done
	ok "kit completo in $KIT"

	msg "3/5 device raggiungibile"
	adb start-server >/dev/null 2>&1
	if ! adb devices | grep -qw device; then
		warn "adb non vede il tablet: accendilo e attiva Debug USB"
		warn "(dopo lo sblocco LineageOS non espone il seriale: servono le regole udev per VID)"
		return 1
	fi
	ok "device: $(adb devices | sed -n '2p' | tr -s '\t' ' ')"

	msg "4/5 firmware"
	local fw; fw="$(adb shell getprop ro.fota.version 2>/dev/null | tr -d '\r')"
	[ -n "$fw" ] && ok "ro.fota.version: $fw"
	case "$fw" in
		"$FW"*) ok "firmware supportato" ;;
		"") warn "non riesco a leggere ro.fota.version (device non stock? gia' sbloccato?)" ;;
		*) die "FIRMWARE NON SUPPORTATO (atteso ${FW}*). Non procedere: gli artefatti di sblocco sono per-firmware." ;;
	esac

	msg "5/5 file da scaricare"
	[ -f "$REPO/$GSI_NAME" ] && ok "GSI presente" || warn "GSI assente: verra' scaricata (~1 GB)"
	[ -n "${PAC_FILE:-}" ] && [ -f "${PAC_FILE:-}" ] && ok "pac: $PAC_FILE" || warn "pac assente: serve solo per il recupero (vedi docs/05)"
}

# --------------------------------------------------------------- unlock
cmd_unlock() {
	[ -x "$SPD_DUMP" ] || die "spd_dump non trovato (SPD_DUMP=...)"
	mkdir -p "$BKP"
	msg "PASSO 1/4 - dump dei TUOI bootloader, sblocco, uboot non verificante"
	cat <<'EOT'
  Serve il tablet in DOWNLOAD MODE:
    1. cavo scollegato, tablet spento
    2. tieni premuto VOL- e inserisci il cavo, tenendo premuto ~10 s
    3. lo schermo resta nero
EOT
	ask "Quando sei pronto, premi Invio e fai subito la combo."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		path "$BKP" blk_size 0x8000 r splloader r uboot e splloader e splloader_bak \
		w uboot "$KIT/fdl2-cboot.bin" reset \
		|| die "fallito. Rilancia ./install.sh unlock (e controlla la FAQ)."
	# i nomi dei file dumpati possono variare: normalizzo
	for n in splloader uboot; do
		if [ ! -f "$BKP/$n" ] && [ -f "$BKP/$n.bin" ]; then cp "$BKP/$n.bin" "$BKP/$n"; fi
	done
	[ -f "$BKP/splloader" ] && [ -f "$BKP/uboot" ] || warn "dump non trovati in $BKP: NON usare ./install.sh restore"
	ok "bootloader originali in $BKP"

	msg "PASSO 2/4 - unlock (l'SPL patchato)"
	warn "Questo comando SEMBRA fallire (usb_recv TIMEOUT). E' il segnale che ha funzionato."
	ask "Fai di nuovo la combo in download mode, poi Invio."
	spd exec_addr 0x4ee8 fdl "$KIT/spl-unlock.bin" 0x5000 || warn "timeout atteso"

	msg "PASSO 3/4 - verifica dell'unlock"
	ask "Combo in download mode, poi Invio."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		path "$BKP" blk_size 0x8000 read_part miscdata 8192 64 m_after.bin reset || true
	if [ -f "$BKP/m_after.bin" ] && tr -d '\000' < "$BKP/m_after.bin" | grep -q .; then
		ok "miscdata contiene i dati di sblocco"
	else
		die "miscdata ancora vuota: non e' sbloccato. Ripeti il passo 2."
	fi

	msg "PASSO 4/4 - AVB disattivato (patch del TUO trustos) + ripristino bootloader"
	ask "Combo in download mode, poi Invio."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		blk_size 0x8000 dis_avb reset || die "dis_avb fallito"
	if [ -f "$BKP/splloader" ] && [ -f "$BKP/uboot" ]; then
		ask "Ultima combo: ripristino i bootloader originali."
		spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
			w splloader "$BKP/splloader" w uboot "$BKP/uboot" reset || warn "ripristino non riuscito"
	fi
	msg "Sblocco completato. Il tablet ora riparte (con lo stock, se non hai ancora flashato la GSI)."
}

# ---------------------------------------------------------------- flash
cmd_flash() {
	msg "1/5 GSI"
	if [ -n "$GSI_LOCAL" ]; then GSI_IMG="$GSI_LOCAL"; else
		if [ ! -f "$REPO/$GSI_NAME" ]; then
			msg "scarico la GSI (~1 GB)"
			curl -L --fail -o "$REPO/gsi.img.gz.part" "$GSI_URL" || die "download fallito"
			gunzip -f "$REPO/gsi.img.gz.part" || die "gz corrotto"
			mv "$REPO/gsi.img" "$REPO/$GSI_NAME"
		fi
		GSI_IMG="$REPO/$GSI_NAME"
	fi
	echo "    sha256 atteso: $GSI_SHA"
	local got; got="$(sha256sum "$GSI_IMG" | cut -d' ' -f1)"
	[ "$got" = "$GSI_SHA" ] && ok "sha256 verificato" || die "sha256 NON corrisponde ($got): riscarica la GSI"

	msg "2/5 fastbootd"
	run adb reboot fastboot; sleep 12
	fb() { timeout 1200 fastboot "$@"; }
	fb devices | grep -q fastboot || die "il tablet non e' in fastbootd"
	[ "$(fb getvar is-userspace 2>&1 | grep -c 'yes')" = 1 ] || warn "is-userspace non 'yes': potrebbe essere il fastboot normale"
	ok "fastbootd pronto"

	msg "3/5 partizioni logiche"
	ask "Cancello 'product' (serve spazio per la GSI: e' reversibile solo riflashando lo stock)."
	run fb delete-logical-partition product
	ask "Scrivo la GSI in 'system' (~2 minuti, non staccare il cavo)."
	run fb flash system "$GSI_IMG" || die "flash di system fallito"

	msg "4/5 AVB: tre vbmeta con verifica disattivata"
	for v in vbmeta vbmeta_system vbmeta_vendor; do
		run fb --disable-verity --disable-verification flash "$v" "$KIT/$v.img" || warn "flash $v fallito"
	done

	msg "5/5 product e misc"
	dd if=/dev/zero of="$REPO/product-empty.img" bs=1M count=64 2>/dev/null
	run "$MKFS" -q -F -L product "$REPO/product-empty.img"
	run fb create-logical-partition product 0x4000000 || warn "product gia' esistente?"
	run fb flash product "$REPO/product-empty.img" || warn "flash product fallito"
	dd if=/dev/zero of="$REPO/misc-zero.img" bs=1M count=1 2>/dev/null
	run fb flash misc "$REPO/misc-zero.img" || warn "flash misc fallito"

	msg "riavvio"
	run fb reboot
	cat <<'EOT'

  Ora il primo avvio: se resta sul logo, manca il wipe dei dati.
    - dalla recovery: "Wipe data/factory reset"
    - oppure: stesso download mode, poi ./install.sh wipe
EOT
}

# ----------------------------------------------------------------- wipe
cmd_wipe() {
	[ -x "$SPD_DUMP" ] || die "spd_dump non trovato"
	msg "wipe di userdata e metadata (da download mode)"
	ask "Combo in download mode, poi Invio."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		e userdata e metadata reset || die "wipe fallito"
	ok "fatto: al prossimo avvio Android ricrea i dati"
}

# --------------------------------------------------------------- verify
cmd_verify() {
	adb devices | grep -qw device || { warn "adb non vede il tablet"; return 1; }
	for p in ro.boot.flash.locked ro.boot.verifiedbootstate ro.boot.vbmeta.device_state ro.build.version.release; do
		printf '  %-32s %s\n' "$p" "$(adb shell getprop "$p" 2>/dev/null | tr -d '\r')"
	done
}

# -------------------------------------------------------------- restore
cmd_restore() {
	[ -f "$BKP/splloader" ] || die "manca $BKP/splloader"
	[ -f "$BKP/uboot" ]    || die "manca $BKP/uboot"
	msg "ripristino dei bootloader originali"
	ask "Combo in download mode, poi Invio."
	spd exec_addr 0x4ee8 fdl "$KIT/fdl1-dl.bin" 0x5000 fdl "$KIT/fdl2-dl.bin" 0x9EFFFE00 exec \
		w splloader "$BKP/splloader" w uboot "$BKP/uboot" reset || die "ripristino fallito"
	ok "fatto"
}

# ----------------------------------------------------------------- main
CMD="${1:-}"; shift || true
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY=1 ;;
		-y) YES=1 ;;
		--gsi) GSI_LOCAL="$2"; shift ;;
		*) die "opzione sconosciuta: $1" ;;
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
