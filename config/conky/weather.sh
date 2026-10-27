#!/usr/bin/env bash
# Thoi tiet tu wttr.in (khong can API key), cache 25 phut.
# Doi thanh pho: sua MT_WEATHER_LOCATION trong ~/.config/mint-mactahoe-vn/widgets.env (de trong = tu nhan theo IP)
[[ -f "$HOME/.config/mint-mactahoe-vn/widgets.env" ]] && . "$HOME/.config/mint-mactahoe-vn/widgets.env"
LOC="${MT_WEATHER_LOCATION:-}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/mint-mactahoe-vn/weather.txt"
mkdir -p "$(dirname "$CACHE")"
if [[ ! -s "$CACHE" || $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -gt 1500 ]]; then
  d=$(curl -fsm 10 "https://wttr.in/${LOC// /+}?format=%l|%t|%C|%h|%w|%f&lang=vi&m") && [[ "$d" == *"|"* ]] && echo "$d" > "$CACHE"
fi
if ! IFS='|' read -r loc temp cond hum wind feels < "$CACHE" 2>/dev/null; then
  echo '${color2}Chưa có dữ liệu (cần Internet)${color}'; exit 0
fi
echo "\${font Inter:weight=Light:size=30}${temp/+/}\${font}  \${font Inter:size=11}${cond}\${font}"
[[ "$loc" =~ ^[0-9.,\ -]+$ ]] && loc="Vị trí hiện tại"
echo "\${color2}${loc%%,*}\${color}"
echo "Cảm giác ${feels/+/} \${alignr}Ẩm ${hum}  Gió ${wind}"
