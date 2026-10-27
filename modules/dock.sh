#!/usr/bin/env bash
# Dock Plank kieu macOS: o giua day man hinh, phong to khi re chuot, tu tranh cua so.

DOCK_APPS=(org.xfce.Thunar nemo google-chrome firefox org.mozilla.firefox code
           org.xfce.terminal xfce4-terminal com.anthropic.Claude rustdesk xfce-settings-manager)

module_dock() {
  title "Dock (Plank)"
  apt_need plank

  local theme_dir="$HOME/.local/share/plank/themes" v
  run mkdir -p "$theme_dir"
  for v in Light Dark; do
    if [[ -d "$HOME/.themes/MacTahoe-$v/plank" ]]; then
      run rm -rf "$theme_dir/MacTahoe-$v"
      run cp -r "$HOME/.themes/MacTahoe-$v/plank" "$theme_dir/MacTahoe-$v"
    fi
  done

  local s=net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/
  run gsettings set $s theme "MacTahoe-$COLOR_VARIANT"
  run gsettings set $s position bottom
  run gsettings set $s alignment center
  run gsettings set $s icon-size 48
  run gsettings set $s zoom-enabled true
  run gsettings set $s zoom-percent 150
  run gsettings set $s hide-mode window-dodge
  run gsettings set $s show-dock-item false
  # Tat bong do cua cua so dock (neu khong se thay 1 vet ke ngang qua man hinh)
  xfset xfwm4 /general/show_dock_shadow bool false

  # Dock trong -> them cac app quen thuoc co tren may
  local items="$HOME/.config/plank/dock1/launchers" app f
  if [[ ! -d "$items" || -z "$(ls -A "$items" 2>/dev/null)" ]]; then
    run mkdir -p "$items"
    for app in "${DOCK_APPS[@]}"; do
      for f in /usr/share/applications/$app.desktop "$HOME/.local/share/applications/$app.desktop"; do
        [[ -f "$f" && "$DRY_RUN" != 1 ]] && printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$f" > "$items/$app.dockitem" && break
      done
    done
  fi

  run mkdir -p "$HOME/.config/autostart"
  [[ "$DRY_RUN" == 1 ]] || printf '[Desktop Entry]\nType=Application\nName=Plank\nExec=plank\nX-GNOME-Autostart-enabled=true\n' \
    > "$HOME/.config/autostart/plank.desktop"
  pgrep -x plank >/dev/null || { [[ "$DRY_RUN" == 1 ]] || (setsid plank &>/dev/null &); }
  ok "Dock da san sang"
}
