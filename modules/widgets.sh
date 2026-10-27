#!/usr/bin/env bash
# Widget man hinh kieu macOS: Dong ho, Thoi tiet, Lich, May tinh, Dang phat nhac.

WIDGET_DIR="$HOME/.config/conky/mint-mactahoe-vn"

# ten | gap_y | chieu cao | chu ky cap nhat (giay)
WIDGETS=(
  "clock|48|120|1"
  "weather|200|110|60"
  "calendar|342|190|60"
  "system|564|180|2"
  "music|776|70|2"
)

module_widgets() {
  title "Widget man hinh"
  apt_need conky-all playerctl fonts-inter curl

  run mkdir -p "$WIDGET_DIR" "$HOME/.config/mint-mactahoe-vn"
  run cp "$REPO_DIR"/config/conky/{card.lua,*.sh} "$WIDGET_DIR/"
  run chmod +x "$WIDGET_DIR"/*.sh

  local item name y h interval
  for item in "${WIDGETS[@]}"; do
    IFS='|' read -r name y h interval <<<"$item"
    [[ "$DRY_RUN" == 1 ]] && { echo "   [dry-run] tao widget $name"; continue; }
    {
      sed -e "s|@@X@@|28|" -e "s|@@Y@@|$y|" -e "s|@@H@@|$h|" \
          -e "s|@@INTERVAL@@|$interval|" -e "s|@@DIR@@|$WIDGET_DIR|" \
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

  [[ "$DRY_RUN" == 1 ]] || cat > "$WIDGET_DIR/start.sh" <<EOF
#!/usr/bin/env bash
# Bat lai toan bo widget
pkill -f 'conky -c $WIDGET_DIR' 2>/dev/null
sleep 1
for c in $WIDGET_DIR/*.conf; do conky -q -c "\$c" & done
EOF
  run chmod +x "$WIDGET_DIR/start.sh"

  run mkdir -p "$HOME/.config/autostart"
  [[ "$DRY_RUN" == 1 ]] || cat > "$HOME/.config/autostart/mint-mactahoe-widgets.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=MacTahoe Widgets
Comment=Dong ho, thoi tiet, lich, may tinh, nhac
Exec=sh -c "sleep 6 && $WIDGET_DIR/start.sh"
X-GNOME-Autostart-enabled=true
EOF

  # Widget can compositor de nen trong suot va bo goc
  xfset xfwm4 /general/use_compositing bool true
  run "$WIDGET_DIR/start.sh"
  ok "Widget dang chay. Doi thanh pho thoi tiet trong $envf"
}
