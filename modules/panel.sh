#!/usr/bin/env bash
# Thanh tren cung kieu macOS:  | ............ | khay | thong bao | am thanh | pin | dong ho | nguon
# Dung lai tu dau panel XFCE (da sao luu truoc do).

module_panel() {
  title "Thanh menu kieu macOS"
  apt_need xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-notifyd

  local apple="$DATA_DIR/apple-black.svg"
  [[ "$COLOR_VARIANT" == Dark ]] && apple="$DATA_DIR/apple-white.svg"
  [[ -f "$apple" || "$DRY_RUN" == 1 ]] || warn "Chua co logo Apple (chay module theme truoc). Dung icon mac dinh."

  run pkill -x xfce4-panel || true
  run xfconf-query -c xfce4-panel -p /panels  -rR 2>/dev/null || true
  run xfconf-query -c xfce4-panel -p /plugins -rR 2>/dev/null || true

  # id:loai plugin, theo thu tu tu trai sang phai
  local plugins=(1:whiskermenu 2:separator 3:systray 4:xapp-status-plugin 5:notification-plugin
                 6:pulseaudio 7:power-manager-plugin 8:clock 9:actions)
  local ids=() item id kind
  for item in "${plugins[@]}"; do
    id=${item%%:*}; kind=${item#*:}
    xfset xfce4-panel "/plugins/plugin-$id" string "$kind"
    ids+=(-t int -s "$id")
  done

  run xfconf-query -c xfce4-panel -p /panels -n -a -t int -s 1
  run xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a "${ids[@]}"
  xfset xfce4-panel /panels/dark-mode                    bool   "$([[ $COLOR_VARIANT == Dark ]] && echo true || echo false)"
  xfset xfce4-panel /panels/panel-1/position             string "p=6;x=0;y=0"
  xfset xfce4-panel /panels/panel-1/position-locked      bool   true
  xfset xfce4-panel /panels/panel-1/length               uint   100
  xfset xfce4-panel /panels/panel-1/size                 uint   28
  xfset xfce4-panel /panels/panel-1/icon-size            uint   16
  xfset xfce4-panel /panels/panel-1/background-style     uint   0
  xfset xfce4-panel /panels/panel-1/enter-opacity        uint   100
  xfset xfce4-panel /panels/panel-1/leave-opacity        uint   100

  # Menu Apple
  [[ -f "$apple" ]] && xfset xfce4-panel /plugins/plugin-1/button-icon string "$apple"
  xfset xfce4-panel /plugins/plugin-1/show-button-title bool false
  xfset xfce4-panel /plugins/plugin-1/show-button-icon  bool true
  # Khoang trong day thanh sang phai
  xfset xfce4-panel /plugins/plugin-2/expand bool true
  xfset xfce4-panel /plugins/plugin-2/style  uint 0
  # Dong ho: "Th 4 28/10   00:05"
  xfset xfce4-panel /plugins/plugin-8/digital-layout      uint   3
  xfset xfce4-panel /plugins/plugin-8/digital-time-format string "%a %d/%m   %H:%M"
  xfset xfce4-panel /plugins/plugin-8/digital-time-font   string "Inter Semi-Bold 10"
  # Nut nguon gon: chi hien menu
  xfset xfce4-panel /plugins/plugin-9/appearance uint 1

  [[ "$DRY_RUN" == 1 ]] || { (setsid xfce4-panel &>/dev/null &); sleep 2; }
  ok "Thanh menu da san sang"
}
