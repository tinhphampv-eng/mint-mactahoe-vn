#!/usr/bin/env bash
# Mang dang dung (tu nhan theo default route) + IP Tailscale neu co.
dev=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
if [[ -n "$dev" ]]; then
  if [[ -d /sys/class/net/$dev/wireless ]]; then
    name="Wi-Fi $(iwgetid -r 2>/dev/null)"
  else
    name="Mạng dây"
  fi
  echo "${name} \${alignr}\${color1}↓\${color} \${downspeed $dev}  \${color1}↑\${color} \${upspeed $dev}"
else
  echo '${color2}Không có mạng${color}'
fi
ts=$(ip -4 -o addr show tailscale0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
[[ -n "$ts" ]] && echo "Tailscale \${alignr}\${color2}${ts}\${color}"
exit 0
