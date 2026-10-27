#!/usr/bin/env bash
# Now playing (Spotify, YouTube in Chrome/Firefox, VLC...) via MPRIS.
echo '${font Inter:size=9}${color2}Now Playing${color}${font}'
if command -v playerctl >/dev/null && s=$(playerctl status 2>/dev/null) && [[ "$s" != Stopped ]]; then
  t=$(playerctl metadata title 2>/dev/null); a=$(playerctl metadata artist 2>/dev/null)
  [[ ${#t} -gt 36 ]] && t="${t:0:35}…"; [[ ${#a} -gt 40 ]] && a="${a:0:39}…"
  [[ "$s" == Playing ]] && icon='❚❚' || icon='▶'
  echo "\${voffset 6}\${font Inter:size=12}${t:-Unknown}\${font}\${alignr}\${font Inter:size=13}${icon}\${font}"
  echo "\${font Inter:size=10}\${color2}${a:-—}\${color}\${font}"
else
  echo '${voffset 6}${font Inter Light:size=13}Not Playing${font}'
  echo '${font Inter:size=10}${color2}Play something on YouTube or Spotify${color}${font}'
fi
