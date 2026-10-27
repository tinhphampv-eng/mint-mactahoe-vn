#!/usr/bin/env bash
# Cac module he thong: bo go tieng Viet, toi uu PC cu, chong sleep, remote, may lam AI Agent.

# ---------- Bo go tieng Viet ----------
module_vietnamese() {
  title "Bo go tieng Viet (ibus-bamboo)"
  if ! pkg_ok ibus-bamboo; then
    run sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo
    run sudo apt-get update
  fi
  apt_need ibus ibus-bamboo
  run im-config -n ibus
  run gsettings set org.freedesktop.ibus.general preload-engines "['xkb:us::eng', 'Bamboo']"
  run gsettings set org.freedesktop.ibus.general engines-order "['xkb:us::eng', 'Bamboo']"
  run gsettings set org.freedesktop.ibus.general.hotkey triggers "['<Super>space']"
  run ibus-daemon -drxR
  ok "Go tieng Viet: Super+Space de chuyen Anh/Viet (kieu Telex). Dang xuat 1 lan de ap dung cho moi app."
}

# ---------- Toi uu PC cu ----------
# Dich vu thuong khong can tren PC ban/may lam viec. Chi tat khi ban dong y tung muc.
OPTIONAL_SERVICES=(
  "NetworkManager-wait-online.service|Cho co mang moi khoi dong xong (lam cham boot)"
  "ModemManager.service|Modem 3G/4G USB"
  "cups.service cups.socket cups.path cups-browsed.service|May in"
  "bluetooth.service|Bluetooth (bo qua neu dung chuot/tai nghe Bluetooth)"
  "openvpn.service|OpenVPN (bo qua neu co dung VPN nay)"
  "qemu-kvm.service|May ao QEMU/KVM"
)
OPTIONAL_AUTOSTART=(mintwelcome sticky warpinator-autostart orca-autostart onboard-autostart
                    org.gnome.Evolution-alarm-notify geoclue-demo-agent print-applet mintreport)

module_optimize() {
  title "Toi uu cho PC cu"
  apt_need preload
  ok "preload: hoc app ban hay mo va nap truoc vao RAM -> mo app nhanh hon tren o HDD"

  local item units desc u
  for item in "${OPTIONAL_SERVICES[@]}"; do
    units=${item%%|*}; desc=${item#*|}
    local present=()
    for u in $units; do unit_exists "$u" && [[ "$(systemctl is-enabled "$u" 2>/dev/null)" == enabled ]] && present+=("$u"); done
    [[ ${#present[@]} -eq 0 ]] && continue
    confirm "Tat ${present[*]} — $desc?" && run sudo systemctl disable --now "${present[@]}"
  done

  # Docker: chi chay khi can (go lenh docker la tu bat)
  if unit_exists docker.service && [[ "$(systemctl is-enabled docker.service)" == enabled ]]; then
    confirm "Docker chi chay khi can (nhanh boot ~20s)?" && {
      run sudo systemctl disable docker.service containerd.service
      run sudo systemctl enable docker.socket
    }
  fi

  # An app tu mo khi dang nhap (khong xoa, bat lai duoc trong Session and Startup)
  local f src dst
  run mkdir -p "$HOME/.config/autostart"
  for f in "${OPTIONAL_AUTOSTART[@]}"; do
    src=/etc/xdg/autostart/$f.desktop; dst=$HOME/.config/autostart/$f.desktop
    [[ -f "$src" ]] || continue
    [[ "$DRY_RUN" == 1 ]] && { echo "   [dry-run] an autostart $f"; continue; }
    cp "$src" "$dst"; sed -i '/^Hidden=/d;/^X-GNOME-Autostart-enabled=/d' "$dst"
    printf 'Hidden=true\nX-GNOME-Autostart-enabled=false\n' >> "$dst"
  done
  ok "Da an cac app tu mo khong can thiet"
}

# ---------- Luon hoat dong, khong sleep ----------
module_nosleep() {
  title "May luon hoat dong (khong sleep)"
  xfset xfce4-power-manager /xfce4-power-manager/inactivity-on-ac           uint 14   # 14 = Never
  xfset xfce4-power-manager /xfce4-power-manager/inactivity-sleep-mode-on-ac uint 1
  xfset xfce4-power-manager /xfce4-power-manager/dpms-enabled               bool false
  xfset xfce4-power-manager /xfce4-power-manager/blank-on-ac                int  0
  run gsettings set apps.light-locker lock-after-screensaver 0 2>/dev/null || true
  run sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ok "Da chan sleep/hibernate. Mo lai: sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target"
}

# ---------- Remote tu Mac / iPhone / Android ----------
module_remote() {
  title "Remote: RustDesk + Tailscale"
  if ! pkg_ok rustdesk; then
    local url
    url=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest \
          | grep -oE 'https://[^"]+/rustdesk-[0-9.]+-x86_64\.deb' | head -1)
    [[ -n "$url" ]] || die "Khong tim thay ban RustDesk moi nhat"
    run curl -fL -o /tmp/rustdesk.deb "$url"
    run sudo apt-get install -y /tmp/rustdesk.deb
  fi
  # Vao bang mat khau co dinh, khong can bam Accept tren may
  run sudo rustdesk --option approve-mode password
  ok "RustDesk: ID cua may la $(rustdesk --get-id 2>/dev/null || echo '?')"
  warn "Dat mat khau co dinh: mo RustDesk > Settings > Security > Set permanent password"

  if ! has tailscale && confirm "Cai Tailscale (mang rieng, remote tu bat ky dau)?"; then
    run sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
  fi
  has tailscale && ! tailscale status &>/dev/null && warn "Dang nhap Tailscale: sudo tailscale up"
}

# ---------- May lam AI Agent / automation ----------
module_ai() {
  title "San sang cho AI Agent & automation"
  apt_need git curl build-essential python3-venv pipx jq
  if ! has docker; then
    apt_need docker.io docker-compose-v2
    run sudo usermod -aG docker "$USER"
    warn "Dang xuat 1 lan de dung docker khong can sudo"
  fi
  # Docker chi bat khi can de khong lam cham may cu
  run sudo systemctl disable docker.service containerd.service 2>/dev/null || true
  run sudo systemctl enable docker.socket
  if ! has node; then
    info "Node.js LTS (cho Claude Code, n8n, MCP server...)"
    run sh -c 'curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs'
  fi
  ok "Xong. Goi y tiep theo:"
  echo "     • Claude Code:  npm install -g @anthropic-ai/claude-code"
  echo "     • n8n:          docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n"
}
