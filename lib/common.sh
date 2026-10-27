#!/usr/bin/env bash
# Ham dung chung cho tat ca module.

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC_DIR="${SRC_DIR:-$HOME/.local/src/mint-mactahoe-vn}"
DATA_DIR="$HOME/.local/share/mint-mactahoe-vn"
BACKUP_ROOT="$HOME/.config/mint-mactahoe-vn/backups"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
COLOR_VARIANT="${COLOR_VARIANT:-Light}"   # Light | Dark

c_reset=$'\033[0m'; c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'; c_dim=$'\033[2m'

info()  { printf '%s==>%s %s\n' "$c_blue" "$c_reset" "$*"; }
ok()    { printf '%s ✓%s  %s\n' "$c_green" "$c_reset" "$*"; }
warn()  { printf '%s !%s  %s\n' "$c_yellow" "$c_reset" "$*"; }
die()   { printf '%s ✗%s  %s\n' "$c_red" "$c_reset" "$*" >&2; exit 1; }
title() { printf '\n%s━━━ %s ━━━%s\n' "$c_blue" "$*" "$c_reset"; }

# Chay lenh, hoac chi in ra khi --dry-run
run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '%s   [dry-run] %s%s\n' "$c_dim" "$*" "$c_reset"
  else
    "$@"
  fi
}

# Hoi Co/Khong. Mac dinh la Co. --yes bo qua cau hoi.
confirm() {
  [[ "$ASSUME_YES" == 1 ]] && return 0
  local ans
  read -r -p "   $1 [Y/n] " ans
  [[ -z "$ans" || "$ans" =~ ^[YyCc] ]]
}

has()        { command -v "$1" &>/dev/null; }
pkg_ok()     { dpkg -s "$1" 2>/dev/null | grep -q 'Status: install ok installed'; }
unit_exists(){ systemctl list-unit-files "$1" --no-legend 2>/dev/null | grep -q .; }

# Cai goi apt con thieu (chi hoi sudo khi that su can)
apt_need() {
  local missing=()
  for p in "$@"; do pkg_ok "$p" || missing+=("$p"); done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  info "Cai goi: ${missing[*]}"
  run sudo apt-get install -y "${missing[@]}"
}

# Clone hoac cap nhat repo upstream (luon lay ban moi nhat)
fetch_repo() {
  local name="$1" url="$2"
  run mkdir -p "$SRC_DIR"
  if [[ -d "$SRC_DIR/$name/.git" ]]; then
    run git -C "$SRC_DIR/$name" pull -q --ff-only
  else
    run git clone -q --depth 1 "$url" "$SRC_DIR/$name"
  fi
  [[ "$DRY_RUN" == 1 ]] || ok "$name @ $(git -C "$SRC_DIR/$name" log -1 --format='%cs %h')"
}

xfset() { # xfset <channel> <property> <type> <value>
  run xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4"
}

require_xfce() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* ]] || warn "Khong phai phien XFCE (${XDG_CURRENT_DESKTOP:-?}). Script viet cho Linux Mint XFCE."
  has xfconf-query || die "Khong tim thay xfconf-query. Script nay chi chay tren XFCE."
}

# Sao luu cau hinh giao dien truoc khi doi. In ra duong dan ban sao luu.
backup_desktop() {
  local dir="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  [[ "$DRY_RUN" == 1 ]] && { echo "   [dry-run] sao luu vao $dir"; return; }
  mkdir -p "$dir"
  for ch in xsettings xfwm4 xfce4-panel xfce4-desktop xfce4-power-manager; do
    xfconf-query -c "$ch" -lv > "$dir/$ch.txt" 2>/dev/null || true
  done
  [[ -d "$HOME/.config/xfce4" ]] && cp -a "$HOME/.config/xfce4" "$dir/xfce4"
  has dconf && dconf dump /net/launchpad/plank/ > "$dir/plank.dconf" 2>/dev/null || true
  [[ -d "$HOME/.config/autostart" ]] && cp -a "$HOME/.config/autostart" "$dir/autostart"
  ln -sfn "$dir" "$BACKUP_ROOT/latest"
  ok "Da sao luu giao dien vao $dir"
}
