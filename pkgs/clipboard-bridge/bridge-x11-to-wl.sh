#!/bin/sh

set -eu

LOCK_DIR="/tmp/clipboard-bridge"
PID_FILE="$LOCK_DIR/x11-to-wl.pid"

TMP_DIR=$(mktemp -d --tmpdir clipboard_sync.XXXXXX) || {
    echo "Failed to create temp dir" >&2
    exit 1
}

# 检测 stdout 是否为终端
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
    local timestamp=$(date '+%H:%M:%S')
    printf '%s[%s]%s X11 → Wayland | %s\n' "$COLOR_CYAN" "$timestamp" "$COLOR_RESET" "$1"
}

log_sync() {
    local direction="$1"
    local type="$2"
    local format="$3"

    case "$direction" in
        "x11->wl")
            printf '%s[%s]%s %s X11 → Wayland | %s%s%s\n' \
                "$COLOR_CYAN" "$(date '+%H:%M:%S')" "$COLOR_RESET" \
                "$COLOR_GREEN✓$COLOR_RESET" \
                "$COLOR_YELLOW" "$type" "$COLOR_RESET$format"
            ;;
    esac
}

log_warn() {
    printf '%s[%s]%s %s X11 → Wayland | Unhandled targets:%s %s\n' \
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
    rm -rf "$TMP_DIR"
}

has_target() {
    printf '%s' "$1" | grep -q "$2"
}

sync_binary_type() {
    local mime_type="$1"
    local label="$2"
    local x11_file="$3"
    local wl_file="$4"

    xclip -selection clipboard -t "$mime_type" -o > "$x11_file" 2>/dev/null
    wl-paste -t "$mime_type" > "$wl_file" 2>/dev/null

    if ! cmp -s "$x11_file" "$wl_file"; then
        wl-copy -t "$mime_type" < "$x11_file"
        log_sync "x11->wl" "$label" " ($mime_type)"
    fi
}

sync_text_type() {
    local mime_type="$1"
    local label="$2"
    local x11_value
    local wl_value

    x11_value=$(xclip -selection clipboard -t "$mime_type" -o 2>/dev/null || true)
    [ -z "$x11_value" ] && return 0

    wl_value=$(wl-paste --type "$mime_type" 2>/dev/null || true)
    if [ "$x11_value" != "$wl_value" ]; then
        printf '%s' "$x11_value" | wl-copy --type "$mime_type"
        log_sync "x11->wl" "$label" " ($mime_type)"
    fi
}

for cmd in xclip wl-copy clipnotify cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: Missing dependency '\''%s'\''\n' "$cmd" >&2
        exit 1
    fi
done

trap cleanup EXIT INT TERM
acquire_instance_lock

log 'Starting X11 -> Wayland sync (Event-driven with clipnotify)...'

clipboard_sync() {
    local current_x11_img="$TMP_DIR/curr_x11.img"
    local current_wl_img="$TMP_DIR/curr_wl.img"
    local last_text=""

    while clipnotify; do
        sleep 0.05

        x11_targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null)
        [ -z "$x11_targets" ] && continue

        handled=false

        if [ "$handled" = false ] && has_target "$x11_targets" 'image/png'; then
            sync_binary_type "image/png" "Image" "$current_x11_img" "$current_wl_img"
            handled=true
        elif [ "$handled" = false ] && has_target "$x11_targets" 'image/jpeg'; then
            sync_binary_type "image/jpeg" "Image" "$current_x11_img" "$current_wl_img"
            handled=true
        elif [ "$handled" = false ] && has_target "$x11_targets" 'image/gif'; then
            sync_binary_type "image/gif" "Image" "$current_x11_img" "$current_wl_img"
            handled=true
        elif [ "$handled" = false ] && has_target "$x11_targets" 'text/html'; then
            sync_text_type "text/html" "Rich Text"
            handled=true
        elif [ "$handled" = false ] && has_target "$x11_targets" 'text/uri-list'; then
            sync_text_type "text/uri-list" "URI List"
            handled=true
        fi

        if [ "$handled" = false ]; then
            current_text=$(wl-paste --type text/plain 2>/dev/null || true)
            x11_text=$(xclip -selection clipboard -o 2>/dev/null || true)
            if [ -n "$x11_text" ] && [ "$x11_text" != "$last_text" ] && [ "$x11_text" != "$current_text" ]; then
                printf '%s' "$x11_text" | wl-copy --type text/plain
                last_text="$x11_text"
                preview="${x11_text%%$'\n'*}"
                preview="${preview:0:50}"
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\\t'/⇥}"
                [ "${#x11_text}" -gt 50 ] && preview="$preview..."
                log_sync "x11->wl" "Text" " \"$preview\""
            fi
            handled=true
        fi

        if [ "$handled" = false ] && [ -n "$x11_targets" ]; then
            log_warn "Unhandled X11 targets: $x11_targets"
        fi
    done
}

log "Clipboard sync service started"
log "Monitoring Wayland ↔ X11 clipboard sync..."

clipboard_sync
