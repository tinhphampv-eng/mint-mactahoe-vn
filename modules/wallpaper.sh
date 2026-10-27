#!/usr/bin/env bash
# Bo hinh nen macOS (Tahoe, Sonoma, Ventura, Monterey, Big Sur) + hinh nen dong doi theo gio nhu macOS.

WALL_DIR="$HOME/.local/share/backgrounds/mint-mactahoe-vn"
WALL_SETS=(Sonoma Ventura Monterey WhiteSur)
WALL_URL=https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k

module_wallpaper() {
  title "Hinh nen macOS + hinh nen dong"
  apt_need curl
  run mkdir -p "$WALL_DIR"
  local s v
  for s in "${WALL_SETS[@]}"; do
    for v in light dark; do
      [[ -s "$WALL_DIR/$s-$v.jpg" ]] || run curl -fsSL -m 180 -o "$WALL_DIR/$s-$v.jpg" "$WALL_URL/$s-$v.jpg" || warn "Khong tai duoc $s-$v"
    done
  done
  [[ -f "$WALL_DIR/MacTahoe-day.jpeg" ]] || warn "Chua co hinh MacTahoe (chay module theme truoc)"

  # Hinh nen dong: 06:00-17:59 dung ban sang, con lai ban toi. Doi cap hinh trong ~/.config/mint-mactahoe-vn/wallpaper.env
  run mkdir -p "$HOME/.config/mint-mactahoe-vn" "$HOME/.config/systemd/user" "$DATA_DIR"
  [[ "$DRY_RUN" == 1 ]] && { echo "   [dry-run] bat hinh nen dong"; return; }
  [[ -f "$HOME/.config/mint-mactahoe-vn/wallpaper.env" ]] || cat > "$HOME/.config/mint-mactahoe-vn/wallpaper.env" <<CFG
# Cap hinh nen dong. Vi du: DAY=$WALL_DIR/Sonoma-light.jpg  NIGHT=$WALL_DIR/Sonoma-dark.jpg
DAY=$WALL_DIR/MacTahoe-day.jpeg
NIGHT=$WALL_DIR/MacTahoe-night.jpeg
DAY_START=6
NIGHT_START=18
CFG
  cat > "$DATA_DIR/dynamic-wallpaper.sh" <<'SH'
#!/usr/bin/env bash
# Doi hinh nen theo gio (goi boi systemd timer moi 10 phut).
. "$HOME/.config/mint-mactahoe-vn/wallpaper.env"
h=$((10#$(date +%H)))
img="$NIGHT"; (( h >= DAY_START && h < NIGHT_START )) && img="$DAY"
[[ -f "$img" ]] || exit 0
for p in $(xfconf-query -c xfce4-desktop -l | grep -E '/last-image$'); do
  [[ "$(xfconf-query -c xfce4-desktop -p "$p")" == "$img" ]] || xfconf-query -c xfce4-desktop -p "$p" -s "$img"
done
SH
  chmod +x "$DATA_DIR/dynamic-wallpaper.sh"
  cat > "$HOME/.config/systemd/user/mactahoe-wallpaper.service" <<UNIT
[Unit]
Description=MacTahoe dynamic wallpaper
[Service]
Type=oneshot
ExecStart=$DATA_DIR/dynamic-wallpaper.sh
UNIT
  cat > "$HOME/.config/systemd/user/mactahoe-wallpaper.timer" <<UNIT
[Unit]
Description=Doi hinh nen theo gio moi 10 phut
[Timer]
OnStartupSec=20
OnUnitActiveSec=10min
[Install]
WantedBy=timers.target
UNIT
  systemctl --user daemon-reload
  systemctl --user enable --now mactahoe-wallpaper.timer >/dev/null 2>&1
  "$DATA_DIR/dynamic-wallpaper.sh"
  ok "Hinh nen dong da bat. Chon hinh khac trong Desktop Settings, hoac doi cap Day/Night trong wallpaper.env"
  echo "     Tat hinh nen dong: systemctl --user disable --now mactahoe-wallpaper.timer"
}
