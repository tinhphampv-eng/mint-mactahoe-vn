#!/usr/bin/env bash
# Widget man hinh kieu macOS 26: the kinh mo bo goc, xep luoi nhu macOS. Giu Alt + keo de di chuyen.

WIDGET_DIR="$HOME/.config/conky/mint-mactahoe-vn"

# Bo cuc: dong ho lon trong suot o tren, ben duoi la luoi the kieu macOS
# (o nho 180x180, o rong 376, cach nhau 16px). x,y la goc tren-trai cua cua so (the + 12px bong).
# ten | x | y | rong | cao | hook lua | chu ky cap nhat (giay)
SMALL=180; WIDE=376; GAP=16; LEFT=16; TOP=34; GRID=$((TOP + 210))
WIDGETS=(
  "bigclock|$LEFT|$TOP|480|186|conky_bigclock|1"
  "weather|$LEFT|$GRID|$SMALL|$SMALL|conky_card|60"
  "calendar|$((LEFT + SMALL + GAP))|$GRID|$SMALL|$SMALL|conky_calendar_card|60"
  "system|$LEFT|$((GRID + SMALL + GAP))|$WIDE|$SMALL|conky_system_card|2"
  "music|$LEFT|$((GRID + 2 * (SMALL + GAP)))|$WIDE|104|conky_card|2"
)

module_widgets() {
  title "Widget man hinh"
  apt_need conky-all playerctl fonts-inter curl wmctrl

  run mkdir -p "$WIDGET_DIR" "$HOME/.config/mint-mactahoe-vn"
  # Ban cu co the de lai widget clock.conf (da thay bang bigclock)
  [[ -f "$WIDGET_DIR/clock.conf" ]] && run mv "$WIDGET_DIR/clock.conf" "$WIDGET_DIR/clock.conf.old"
  run cp "$REPO_DIR"/config/conky/{widgets.lua,*.sh} "$WIDGET_DIR/"
  run chmod +x "$WIDGET_DIR"/*.sh

  local item name x y w h hook interval
  for item in "${WIDGETS[@]}"; do
    IFS='|' read -r name x y w h hook interval <<<"$item"
    [[ "$DRY_RUN" == 1 ]] && { echo "   [dry-run] tao widget $name"; continue; }
    {
      # Cua so = the + 12px bong do moi canh; vung chu = cua so - 2*28px le
      sed -e "s|@@X@@|$x|g" -e "s|@@Y@@|$y|g" -e "s|@@W@@|$((w + 24 - 56))|g" -e "s|@@H@@|$((h + 24 - 56))|g" \
          -e "s|@@HOOK@@|${hook#conky_}|g" -e "s|@@NAME@@|$name|g" \
          -e "s|@@INTERVAL@@|$interval|g" -e "s|@@DIR@@|$WIDGET_DIR|g" \
          "$REPO_DIR/config/conky/base.conf.in"
      echo; echo 'conky.text = [['
      sed "s|@@DIR@@|$WIDGET_DIR|g" "$REPO_DIR/config/conky/$name.text"
      echo ']]'
    } > "$WIDGET_DIR/$name.conf"
  done

  local envf="$HOME/.config/mint-mactahoe-vn/widgets.env"
  [[ -f "$envf" || "$DRY_RUN" == 1 ]] || cat > "$envf" <<'EOF'
# Thanh pho cho widget thoi tiet, vi du: MT_WEATHER_LOCATION="Da Nang"
# De trong = tu nhan theo IP.
MT_WEATHER_LOCATION=""
EOF

  if [[ "$DRY_RUN" != 1 ]]; then
    {
      echo '#!/usr/bin/env bash'
      echo '# Bat lai toan bo widget va dat dung vi tri luoi (trinh quan ly cua so hay tu doi cho).'
      echo 'pkill -x conky 2>/dev/null; sleep 1'
      # Bat lan luot: bat cung luc nhieu conky de bi crash (Xlib/fontconfig)
      echo "for c in $WIDGET_DIR/*.conf; do conky -q -c \"\$c\" & sleep 1; done"
      echo 'sleep 3'
      for item in "${WIDGETS[@]}"; do
        IFS='|' read -r name x y _ <<<"$item"
        echo "wmctrl -r mactahoe-$name -e 0,$x,$y,-1,-1 2>/dev/null"
      done
    } > "$WIDGET_DIR/start.sh"
  fi
  run chmod +x "$WIDGET_DIR/start.sh"

  run mkdir -p "$HOME/.config/autostart"
  [[ "$DRY_RUN" == 1 ]] || cat > "$HOME/.config/autostart/mint-mactahoe-widgets.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=MacTahoe Widgets
Comment=Big clock, Weather, Calendar, System, Now Playing
Exec=sh -c "sleep 6 && $WIDGET_DIR/start.sh"
X-GNOME-Autostart-enabled=true
EOF

  # Widget can compositor de nen trong suot va bo goc
  xfset xfwm4 /general/use_compositing bool true
  run "$WIDGET_DIR/start.sh"
  ok "Widget dang chay. Giu Alt + keo de di chuyen. Doi thanh pho thoi tiet trong $envf"
}
