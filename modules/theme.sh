#!/usr/bin/env bash
# Theme MacTahoe (GTK + XFWM), icon, con tro, font, hinh nen. Luon lay ban moi nhat tu upstream.

module_theme() {
  title "Theme MacTahoe ($COLOR_VARIANT)"
  apt_need git sassc libglib2.0-dev-bin libxml2-utils gtk2-engines-murrine gnome-themes-extra fonts-inter

  fetch_repo MacTahoe-gtk-theme  https://github.com/vinceliuice/MacTahoe-gtk-theme.git
  fetch_repo MacTahoe-icon-theme https://github.com/vinceliuice/MacTahoe-icon-theme.git
  fetch_repo WhiteSur-cursors    https://github.com/vinceliuice/WhiteSur-cursors.git

  info "Cai GTK theme (sang + toi)..."
  ( cd "$SRC_DIR/MacTahoe-gtk-theme" && run ./install.sh -c light -c dark ) || die "Cai GTK theme that bai"
  info "Cai icon..."
  ( cd "$SRC_DIR/MacTahoe-icon-theme" && run ./install.sh ) >/dev/null || die "Cai icon that bai"
  info "Cai con tro chuot..."
  ( cd "$SRC_DIR/WhiteSur-cursors" && run ./install.sh ) >/dev/null || die "Cai con tro that bai"

  local icon="MacTahoe"; [[ "$COLOR_VARIANT" == Dark ]] && icon="MacTahoe-dark"
  [[ "$COLOR_VARIANT" == Dark ]] || { whisker_icons && icon="MacTahoe-VN"; }
  run mkdir -p "$HOME/.config/gtk-3.0"
  run cp "$REPO_DIR/config/gtk/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
  xfset xsettings /Net/ThemeName        string "MacTahoe-$COLOR_VARIANT"
  xfset xsettings /Net/IconThemeName    string "$icon"
  xfset xsettings /Gtk/CursorThemeName  string "WhiteSur-cursors"
  xfset xsettings /Gtk/FontName         string "Inter 10"
  xfset xsettings /Gtk/MonospaceFontName string "DejaVu Sans Mono 10"
  xfset xfwm4 /general/theme            string "MacTahoe-$COLOR_VARIANT"
  xfset xfwm4 /general/title_font       string "Inter Semi-Bold 10"
  xfset xfwm4 /general/button_layout    string "CHM|"      # nut do-vang-xanh ben trai nhu macOS
  xfset xfwm4 /general/title_alignment  string "center"
  xfset xfwm4 /general/use_compositing  bool   true

  # Hinh nen day/night
  local bg="$HOME/.local/share/backgrounds/mint-mactahoe-vn"
  run mkdir -p "$bg"
  run cp "$SRC_DIR"/MacTahoe-gtk-theme/wallpaper/MacTahoe-{day,night}.jpeg "$bg/"
  local img="$bg/MacTahoe-day.jpeg"; [[ "$COLOR_VARIANT" == Dark ]] && img="$bg/MacTahoe-night.jpeg"
  local p
  for p in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$'); do
    xfset xfce4-desktop "$p" string "$img"
    xfset xfce4-desktop "${p%/last-image}/image-style" int 5
  done

  # Logo Apple cho menu (lay tu asset cua MacTahoe)
  run mkdir -p "$DATA_DIR"
  run cp "$SRC_DIR/MacTahoe-gtk-theme/src/assets/gnome-shell/activities-black/activities-apple.svg" "$DATA_DIR/apple-black.svg"
  run cp "$SRC_DIR/MacTahoe-gtk-theme/src/assets/gnome-shell/activities/activities-apple.svg" "$DATA_DIR/apple-white.svg"

  ok "Da ap dung MacTahoe-$COLOR_VARIANT"
}

# MacTahoe sang dung icon nguon mau trang (#f2f2f2) danh cho panel toi, nen tren menu Whisker nen sang
# gan nhu khong thay. CSS khong doi mau duoc icon nay, nen tao theme MacTahoe-VN ke thua MacTahoe,
# chi thay cac icon nguon bang ban mau toi.
whisker_icons() {
  local src="$HOME/.local/share/icons/MacTahoe/status/22" dst="$HOME/.local/share/icons/MacTahoe-VN"
  [[ -d "$src" || "$DRY_RUN" == 1 ]] || { warn "Khong thay $src, bo qua icon nguon."; return 1; }
  run mkdir -p "$dst/scalable"
  if [[ "$DRY_RUN" != 1 ]]; then
    printf '%s\n' '[Icon Theme]' 'Name=MacTahoe-VN' 'Comment=MacTahoe + icon nguon toi cho menu Whisker' \
      'Inherits=MacTahoe,hicolor,breeze' 'Directories=scalable' '' \
      '[scalable]' 'Size=22' 'MinSize=8' 'MaxSize=64' 'Context=Status' 'Type=Scalable' > "$dst/index.theme"
  fi
  local n
  # Whisker tim ten xfsm-* truoc, system-* sau
  for n in system-lock-screen system-reboot system-shutdown system-suspend system-log-out \
           xfsm-lock xfsm-reboot xfsm-shutdown xfsm-suspend xfsm-logout; do
    if [[ "$DRY_RUN" == 1 ]]; then echo "   [dry-run] $n.svg (#f2f2f2 -> #1d1d1f)"; continue; fi
    sed 's/#f2f2f2/#1d1d1f/Ig' "$src/$n.svg" > "$dst/scalable/$n.svg"
  done
}
