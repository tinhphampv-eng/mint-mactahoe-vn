#!/usr/bin/env bash
# Bo app open source ArtCraft (https://getartcraft.com/apps) thay the Photoshop, Illustrator, Acrobat, Word, Excel.
# Tai ban .deb moi nhat tu GitHub cua storytold, kiem tra SHA-256 roi moi cai.

# Mac dinh 5 app pho bien. Doi bang bien CRAFT_APPS="photocraft wordcraft ..."
CRAFT_APPS="${CRAFT_APPS:-photocraft vectorcraft pdfcraft wordcraft gridcraft}"

declare -A CRAFT_DESC=(
  [photocraft]="PhotoCraft  — chinh sua anh, mo file PSD (thay Photoshop)"
  [vectorcraft]="VectorCraft — ve vector (thay Illustrator)"
  [pdfcraft]="PdfCraft    — doc, sua, ky PDF (thay Acrobat)"
  [wordcraft]="WordCraft   — soan van ban, mo .docx (thay Word)"
  [gridcraft]="GridCraft   — bang tinh, mo .xlsx (thay Excel)"
  [lightcraft]="LightCraft  — thu vien anh, xu ly RAW (thay Lightroom)"
  [filmcraft]="FilmCraft   — dung video (thay Premiere)"
  [deckcraft]="DeckCraft   — trinh chieu (thay PowerPoint)"
  [figcraft]="FigCraft    — thiet ke giao dien (thay Figma)"
)

module_craft() {
  title "ArtCraft: app open source thay phan mem tra phi"
  apt_need curl python3
  warn "Cac app ArtCraft dang o giai doan alpha/dang phat trien: dung thu, chua nen thay han cho cong viec quan trong."

  local tmp="/tmp/mint-mactahoe-craft" app api tag url sums deb
  run mkdir -p "$tmp"
  for app in $CRAFT_APPS; do
    info "${CRAFT_DESC[$app]:-$app}"
    api=$(curl -fsSL "https://api.github.com/repos/storytold/$app/releases/latest") || { warn "Khong lay duoc thong tin $app"; continue; }
    read -r tag url sums < <(python3 -I -c '
import json, sys
d = json.load(sys.stdin)
urls = [a["browser_download_url"] for a in d.get("assets", [])]
deb = next((u for u in urls if u.endswith("linux-x86_64.deb")), "")
sha = next((u for u in urls if u.endswith("SHA256SUMS.txt")), "")
print(d.get("tag_name", "?"), deb or "-", sha or "-")' <<<"$api")
    [[ "$url" == - ]] && url=""; [[ "$sums" == - ]] && sums=""
    [[ -n "$url" ]] || { warn "$app $tag chua co ban .deb cho Linux x86_64"; continue; }
    if pkg_ok "$app" && [[ "$(dpkg-query -W -f='${Version}' "$app" 2>/dev/null)" == "${tag#v}"* ]]; then
      ok "$app $tag da cai"; continue
    fi
    deb="$tmp/${url##*/}"
    run curl -fL --progress-bar -o "$deb" "$url" || { warn "Tai $app that bai"; continue; }
    if [[ -n "$sums" && "$DRY_RUN" != 1 ]]; then
      (cd "$tmp" && curl -fsSL "$sums" | grep " ${url##*/}\$" | sha256sum -c --quiet -) \
        || { warn "SHA-256 cua $app khong khop, bo qua"; continue; }
      ok "Da kiem tra SHA-256"
    fi
    run sudo apt-get install -y "$deb" && ok "Da cai $app $tag"
  done
  echo "     Mo app trong Menu, hoac them vao Dock. Cap nhat: chay lai './install.sh craft'"
}
