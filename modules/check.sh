#!/usr/bin/env bash
# "Kham may" truoc khi cai: phan cung, o dia, thoi gian boot, dich vu nang, goi y nang cap.

module_check() {
  title "Kham may"
  local cpu ram disk rota model boot
  cpu=$(lscpu | awk -F: '/Model name/{gsub(/^ +/,"",$2); print $2; exit}')
  ram=$(free -h | awk '/Mem:/{print $2" (con trong "$7")"}')
  disk=$(findmnt -no SOURCE / | sed 's|/dev/||; s|[0-9]*$||; s|p$||')
  rota=$(cat "/sys/block/$disk/queue/rotational" 2>/dev/null)
  model=$(cat "/sys/block/$disk/device/model" 2>/dev/null | xargs)
  boot=$(systemd-analyze 2>/dev/null | head -1 | sed 's/.*= //')

  printf '   %-14s %s\n' "He dieu hanh" "$(lsb_release -ds 2>/dev/null) — ${XDG_CURRENT_DESKTOP:-?}"
  printf '   %-14s %s (%s luong)\n' "CPU" "$cpu" "$(nproc)"
  printf '   %-14s %s\n' "RAM" "$ram"
  printf '   %-14s %s %s\n' "O he thong" "${model:-$disk}" "$([[ $rota == 1 ]] && echo '— HDD (o co)' || echo '— SSD')"
  printf '   %-14s %s\n' "Thoi gian boot" "${boot:-?}"
  printf '   %-14s %s\n' "GPU" "$(lspci | grep -iE 'vga|3d' | sed 's/.*: //' | head -1)"

  echo; info "5 dich vu khoi dong lau nhat:"
  systemd-analyze blame 2>/dev/null | head -5 | sed 's/^/     /'

  echo; info "Goi y:"
  [[ $rota == 1 ]] && echo "     • O HDD la nut that co chai lon nhat. Thay SSD SATA 500GB (~800k) se nhanh hon 3-5 lan."
  local avail_mb; avail_mb=$(free -m | awk '/Mem:/{print $7}')
  (( avail_mb < 2000 )) && echo "     • RAM con it (<2GB). Nen nang len 8GB tro len."
  pkg_ok preload || echo "     • Chua co preload: chay './install.sh optimize'"
  [[ "$(systemctl is-enabled sleep.target 2>/dev/null)" == masked ]] || echo "     • May van co the tu sleep: chay './install.sh nosleep' neu can remote 24/7"
  echo "     • Chay './install.sh all' de cai tron bo, hoac chon tung module (xem --help)."
}
