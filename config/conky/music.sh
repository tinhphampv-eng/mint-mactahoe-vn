#!/usr/bin/env bash
# Bai hat dang phat (Spotify, YouTube tren Chrome/Firefox, VLC...) qua MPRIS.
if command -v playerctl >/dev/null && s=$(playerctl status 2>/dev/null) && [[ "$s" != Stopped ]]; then
  t=$(playerctl metadata title 2>/dev/null | cut -c1-34)
  a=$(playerctl metadata artist 2>/dev/null | cut -c1-34)
  [[ "$s" == Playing ]] && icon='▶' || icon='❚❚'
  echo "\${font Inter:weight=SemiBold:size=11}${t:-Không rõ tên}\${font}"
  echo "\${color2}${a:-—}\${color} \${alignr}\${color1}${icon}\${color}"
else
  echo '${color2}Không có nhạc đang phát${color}'
fi
