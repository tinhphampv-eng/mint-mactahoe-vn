#!/usr/bin/env bash
# mint-mactahoe-vn — Bien PC Windows cu thanh may Linux Mint dep nhu macOS Tahoe, san sang cho AI Agent.
# https://github.com/tinhphampv-eng/mint-mactahoe-vn
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$REPO_DIR/lib/common.sh"
for m in "$REPO_DIR"/modules/*.sh; do . "$m"; done

VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo dev)"
LOOK_MODULES=(theme wallpaper panel dock widgets)
ALL_MODULES=(theme wallpaper panel dock widgets vietnamese optimize nosleep remote)

usage() {
  cat <<EOF
mint-mactahoe-vn $VERSION

Cach dung:  ./install.sh [tuy chon] [module...]

Module:
  check        Kham may: CPU, RAM, HDD/SSD, thoi gian boot, goi y nang cap (khong thay doi gi)
  look         Tron bo giao dien = theme + wallpaper + panel + dock + widgets
    theme        Theme MacTahoe, icon, con tro, font Inter, hinh nen
    wallpaper    10 hinh nen macOS + hinh nen dong doi theo gio
    panel        Thanh menu tren cung kieu macOS (logo Apple, dong ho, khay)
    dock         Dock Plank o day man hinh
    widgets      Widget kieu macOS 26: Clock, Weather, Calendar, Now Playing, System (Alt+keo de di chuyen)
  vietnamese   Bo go tieng Viet ibus-bamboo
  optimize     Toi uu PC cu: preload, tat dich vu thua (hoi tung muc)
  nosleep      May luon hoat dong, khong sleep (de remote 24/7)
  remote       RustDesk + Tailscale: dieu khien tu Mac, iPhone, Android
  ai           Docker (chay khi can), Node.js, Python: san sang cho AI Agent / n8n
  craft        App open source ArtCraft: PhotoCraft, VectorCraft, PdfCraft, WordCraft, GridCraft
               (thay Photoshop, Illustrator, Acrobat, Word, Excel). Chon app: CRAFT_APPS="photocraft gridcraft"
  all          look + vietnamese + optimize + nosleep + remote

Tuy chon:
  --dark       Dung ban Toi (mac dinh: Sang)
  --dry-run    Chi in ra se lam gi, khong thay doi may
  -y, --yes    Khong hoi xac nhan
  -h, --help   Hien huong dan nay

Vi du:
  ./install.sh check
  ./install.sh look
  ./install.sh --dark look vietnamese
  ./install.sh all ai craft
Go cai dat:  ./uninstall.sh
EOF
}

modules=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dark)      COLOR_VARIANT=Dark ;;
    --light)     COLOR_VARIANT=Light ;;
    --dry-run)   DRY_RUN=1 ;;
    -y|--yes)    ASSUME_YES=1 ;;
    -h|--help)   usage; exit 0 ;;
    look)        modules+=("${LOOK_MODULES[@]}") ;;
    all)         modules+=("${ALL_MODULES[@]}") ;;
    check|theme|wallpaper|panel|dock|widgets|vietnamese|optimize|nosleep|remote|ai|craft) modules+=("$1") ;;
    *) usage; die "Khong hieu tham so: $1" ;;
  esac
  shift
done
[[ ${#modules[@]} -eq 0 ]] && { usage; exit 0; }
[[ $EUID -eq 0 ]] && die "Dung chay bang sudo. Script se tu hoi mat khau khi can."

printf '%s\n' "$c_blue" \
  '   ┌──────────────────────────────────────────────┐' \
  '   │   mint-mactahoe-vn  ·  Linux Mint × macOS 26  │' \
  '   └──────────────────────────────────────────────┘' "$c_reset"

# Bo trung lap, giu thu tu
declare -A seen; ordered=()
for m in "${modules[@]}"; do [[ -n "${seen[$m]:-}" ]] || { seen[$m]=1; ordered+=("$m"); }; done

needs_desktop=0
for m in "${ordered[@]}"; do [[ " theme wallpaper panel dock widgets nosleep " == *" $m "* ]] && needs_desktop=1; done
if [[ $needs_desktop == 1 ]]; then require_xfce; backup_desktop; fi
only_check=0; [[ "${ordered[*]}" == check ]] && only_check=1
if [[ $only_check == 0 && "$DRY_RUN" != 1 ]]; then
  info "Can quyen sudo de cai goi (chi hoi 1 lan)"
  sudo -v || die "Can quyen sudo"
  sudo apt-get update -qq || warn "apt update loi, van tiep tuc"
fi

for m in "${ordered[@]}"; do "module_$m"; done

title "Hoan tat"
ok "Da chay: ${ordered[*]}"
if [[ $needs_desktop == 1 ]]; then echo "   Khong ung? Khoi phuc giao dien cu:  ./uninstall.sh"; fi
