#!/usr/bin/env bash
# Khoi phuc giao dien tu ban sao luu gan nhat (hoac ban chi dinh). Khong go goi he thong.
set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$REPO_DIR/lib/common.sh"

src="${1:-$BACKUP_ROOT/latest}"
[[ -d "$src" ]] || die "Khong tim thay ban sao luu ($src). Cac ban co: $(ls "$BACKUP_ROOT" 2>/dev/null | tr '\n' ' ')"
src="$(readlink -f "$src")"
title "Khoi phuc giao dien tu $src"
confirm "Tiep tuc?" || exit 0

# Tat widget, khoi phuc panel/theme
pkill -f "conky -c $HOME/.config/conky/mint-mactahoe-vn" 2>/dev/null
rm -f "$HOME/.config/autostart/mint-mactahoe-widgets.desktop"
pkill -x xfce4-panel 2>/dev/null
xfconf-query -c xfce4-panel -p /panels -rR 2>/dev/null
xfconf-query -c xfce4-panel -p /plugins -rR 2>/dev/null

restore_channel() { # doc file "property  value" do xfconf-query -lv xuat ra
  local ch="$1" file="$src/$1.txt" prop val
  [[ -f "$file" ]] || return 0
  while IFS= read -r line; do
    prop=${line%% *}; val=$(sed -E 's/^[^ ]+ +//' <<<"$line")
    [[ "$val" == "<<UNSUPPORTED>>" || -z "$prop" ]] && continue
    xfconf-query -c "$ch" -p "$prop" -s "$val" 2>/dev/null
  done < "$file"
}
for ch in xsettings xfwm4 xfce4-desktop xfce4-power-manager; do restore_channel "$ch"; done

# Panel co nhieu mang (plugin-ids) nen khoi phuc bang file xml goc
if [[ -f "$src/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ]]; then
  cp "$src/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
  cp -a "$src/xfce4/panel/." "$HOME/.config/xfce4/panel/" 2>/dev/null
  pkill -x xfconfd 2>/dev/null; sleep 1
fi
[[ -f "$src/plank.dconf" ]] && dconf load /net/launchpad/plank/ < "$src/plank.dconf"
(setsid xfce4-panel &>/dev/null &)

ok "Da khoi phuc. Theme/icon MacTahoe van con trong ~/.themes va ~/.local/share/icons neu ban muon dung lai."
echo "   Cac thay doi he thong (preload, dich vu, chong sleep, RustDesk...) duoc giu nguyen."
echo "   Mo lai sleep: sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target"
