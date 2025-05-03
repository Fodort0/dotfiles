#!/usr/bin/env bash
set -u

CACHE="$HOME/.config/ml4w/cache/current_wallpaper"
DIR=$(dirname "$CACHE")                      # directory to watch
LIGHT="$HOME/.config/kitty/light.conf"
DARK="$HOME/.config/kitty/dark.conf"
DEST="$HOME/.config/kitty/colors-current.conf"
COOLDOWN=0.0

log() { printf '[kitty‑watcher] %s\n' "$*" >>"$HOME/.cache/kitty-theme.log"; }

push_to_all() {          # $1 = palette file
    printf 'include %s\n' "$1" > "$DEST"        # seed FUTURE kitty
    for pid in $(pgrep kitty); do
        kitty @ --to "unix:@kitty-${pid}" \
            set-colors --all --configured "$1"  >/dev/null 2>&1 || true
    done
    log "pushed $(basename "$1") to $(wc -l <<<"$(pgrep kitty)") processes"
}

current=""
apply() {
    local wp="$1"
    case "${wp,,}" in
        */dark.png)  [[ $current != dark  ]] && push_to_all "$DARK"  && current=dark  ;;
        */light.png) [[ $current != light ]] && push_to_all "$LIGHT" && current=light ;;
    esac
}

# ── initial attempt (file may not exist yet) ──────────────────────────────
[[ -f $CACHE ]] && apply "$(tr -d '\n' < "$CACHE")"

# ── watch the directory for *any* file close‑write ────────────────────────
inotifywait -mqe close_write --format '%w%f' "$DIR" |
while read -r changed; do
    [[ $changed == "$CACHE" ]] || continue        # ignore other files
    sleep "$COOLDOWN"
    apply "$(tr -d '\n' < "$CACHE" 2>/dev/null || true)"
done
