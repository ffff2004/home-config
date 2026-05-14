#!/bin/sh

set -eu

LOCK_DIR="/tmp/clipboard-bridge"
PID_FILE="$LOCK_DIR/wl-to-x11.pid"

if [ -t 1 ]; then
    COLOR_RESET='\033[0m'
    COLOR_GREEN='\033[32m'
    COLOR_YELLOW='\033[33m'
    COLOR_CYAN='\033[36m'
else
    COLOR_RESET=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_CYAN=''
fi

log() {
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    printf '%s[%s]%s Wayland → X11 | %s\n' "$COLOR_CYAN" "$timestamp" "$COLOR_RESET" "$1"
}

log_sync() {
    local type="$1"
    local detail="$2"
    printf '%s[%s]%s %s Wayland → X11 | %s%s%s\n' \
        "$COLOR_CYAN" "$(date '+%H:%M:%S')" "$COLOR_RESET" \
        "$COLOR_GREEN✓$COLOR_RESET" \
        "$COLOR_YELLOW" "$type" "$COLOR_RESET$detail"
}

log_warn() {
    printf '%s[%s]%s %s Wayland → X11 | Unhandled MIME types:%s %s\n' \
        "$COLOR_CYAN" "$(date '+%H:%M:%S')" "$COLOR_RESET" \
        "$COLOR_YELLOW" "$1" "$COLOR_RESET"
}

acquire_instance_lock() {
    mkdir -p "$LOCK_DIR"

    if [ -e "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            exit 0
        fi
        rm -f "$PID_FILE"
    fi

    printf '%d\n' "$$" > "$PID_FILE"
}

cleanup() {
    rm -f "$PID_FILE"
}

sync_once() {
    types=$(wl-paste --list-types 2>/dev/null || true)
    synced=false

    case "$types" in
        *"image/png"*)
            wl-paste --type image/png | xclip -selection clipboard -t image/png
            log_sync "Image" " (image/png)"
            synced=true
            ;;
        *"image/jpeg"*)
            wl-paste --type image/jpeg | xclip -selection clipboard -t image/jpeg
            log_sync "Image" " (image/jpeg)"
            synced=true
            ;;
        *"image/gif"*)
            wl-paste --type image/gif | xclip -selection clipboard -t image/gif
            log_sync "Image" " (image/gif)"
            synced=true
            ;;
        *"text/html"*)
            wl-paste --type text/html | xclip -selection clipboard -t text/html
            log_sync "Rich Text" " (text/html)"
            synced=true
            ;;
        *"text/uri-list"*)
            wl-paste --type text/uri-list | xclip -selection clipboard -t text/uri-list
            log_sync "URI List" " (text/uri-list)"
            synced=true
            ;;
    esac

    if [ "$synced" = false ]; then
        if wl-paste --type text/plain >/dev/null 2>&1; then
            text=$(wl-paste --type text/plain 2>/dev/null || true)
            if [ -n "$text" ]; then
                printf '%s' "$text" | xclip -selection clipboard
                preview="${text%%$'\n'*}"
                preview="${preview:0:50}"
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [ "${#text}" -gt 50 ] && preview="$preview..."
                log_sync "Text" " \"$preview\""
                synced=true
            fi
        fi
    fi

    if [ "$synced" = false ] && [ -n "$types" ]; then
        log_warn "$types"
    fi
}

if [ "${1-}" = "--sync-once" ]; then
    sync_once
    exit 0
fi

for cmd in wl-paste xclip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: Missing dependency "%s"\n' "$cmd" >&2
        exit 1
    fi
done

trap cleanup EXIT INT TERM
acquire_instance_lock

log "Clipboard watch service started"
sync_once
log "Monitoring Wayland -> X11 clipboard sync..."

exec wl-paste --watch "$0" --sync-once
