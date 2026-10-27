#!/usr/bin/env bash
# Active network (from the default route) and Tailscale IP, for the right column of the System widget.
g='${goto 292}'
dev=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
echo "$g\${font Inter:size=8}\${color2}NETWORK\${color}\${font}"
if [[ -n "$dev" ]]; then
  [[ -d /sys/class/net/$dev/wireless ]] && name="Wi-Fi" || name="Ethernet"
  echo "$g\${font Inter:size=9}↓ \${downspeedf $dev}K\${font}"
  echo "$g\${font Inter:size=9}\${color2}↑ \${upspeedf $dev}K\${color}\${font}"
else
  echo "$g\${color2}Offline\${color}"
fi
exit 0
