#!/usr/bin/env bash
# Weather from wttr.in (no API key), cached for 25 minutes.
# Set your city in ~/.config/mint-mactahoe-vn/widgets.env (empty = detect by IP)
[[ -f "$HOME/.config/mint-mactahoe-vn/widgets.env" ]] && . "$HOME/.config/mint-mactahoe-vn/widgets.env"
LOC="${MT_WEATHER_LOCATION:-}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/mint-mactahoe-vn/weather-en.txt"
mkdir -p "$(dirname "$CACHE")"
if [[ ! -s "$CACHE" || $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -gt 1500 ]]; then
  d=$(curl -fsm 10 "https://wttr.in/${LOC// /+}?format=%l|%t|%C|%h|%f&m") && [[ "$d" == *"|"* ]] && echo "$d" > "$CACHE"
fi
if ! IFS='|' read -r loc temp cond hum feels < "$CACHE" 2>/dev/null; then
  echo '${font Inter:bold:size=10}Weather${font}'
  echo '${color2}No data (offline)${color}'; exit 0
fi
[[ -n "$LOC" ]] && loc="$LOC"
[[ "$loc" =~ ^[0-9.,\ -]+$ ]] && loc="My Location"
temp=${temp/+/}; feels=${feels/+/}
echo "\${font Inter:size=9}\${color2}${loc%%,*}\${color}\${font}"
echo "\${voffset -2}\${font Inter Light:size=38}${temp%C}\${font}"
echo "\${voffset 4}\${font Inter:size=10}${cond:0:17}\${font}"
echo "\${font Inter:size=9}\${color2}Feels ${feels%C}\${color}\${font}"
