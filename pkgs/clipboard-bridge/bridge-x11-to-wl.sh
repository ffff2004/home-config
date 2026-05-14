LOCK_FILE="/tmp/clipboard_bridge_lock"

TMP_DIR=$(mktemp -d --tmpdir clipboard_sync.XXXXXX) || {
    echo "Failed to create temp dir" >&2
    exit 1
}
trap 'rm -rf "$TMP_DIR"; exit' INT TERM EXIT

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

for cmd in xclip wl-copy clipnotify cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: Missing dependency '\''%s'\''\n' "$cmd" >&2
        exit 1
    fi
done

log 'Starting X11 -> Wayland sync (Event-driven with clipnotify)...'

clipboard_sync() {
    local current_x11_img="$TMP_DIR/curr_x11.img"
    local current_wl_img="$TMP_DIR/curr_wl.img"
    local last_x11_img="$TMP_DIR/last_x11.img"
    local last_text=""

    # rm -f "$LOCK_FILE"

    while clipnotify; do
        # if [ -f "$LOCK_FILE" ]; then
        #     sleep 0.2
        #     continue
        # fi

        # echo x11 > "$LOCK_FILE"
        sleep 0.05

        x11_targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null)
        [ -z "$x11_targets" ] && continue

        handled=false

        # Image types
        if [ -z "$handled" ] && printf '%s' "$x11_targets" | grep -q 'image/png'; then
            xclip -selection clipboard -t image/png -o > "$current_x11_img" 2>/dev/null
            wl-paste -t image/png > "$current_wl_img" 2>/dev/null
            if ! cmp -s "$current_x11_img" "$current_wl_img"; then
                wl-copy -t image/png < "$current_x11_img"
                cp "$current_x11_img" "$last_x11_img"
                log_sync "x11->wl" "Image" " (image/png)"
            fi
            handled=true
        elif [ -z "$handled" ] && printf '%s' "$x11_targets" | grep -q 'image/jpeg'; then
            xclip -selection clipboard -t image/jpeg -o > "$current_x11_img" 2>/dev/null
            wl-paste -t image/jpeg > "$current_wl_img" 2>/dev/null
            if ! cmp -s "$current_x11_img" "$current_wl_img"; then
                wl-copy -t image/jpeg < "$current_x11_img"
                cp "$current_x11_img" "$last_x11_img"
                log_sync "x11->wl" "Image" " (image/jpeg)"
            fi
            handled=true
        elif [ -z "$handled" ] && printf '%s' "$x11_targets" | grep -q 'image/gif'; then
            xclip -selection clipboard -t image/gif -o > "$current_x11_img" 2>/dev/null
            wl-paste -t image/gif > "$current_wl_img" 2>/dev/null
            if ! cmp -s "$current_x11_img" "$current_wl_img"; then
                wl-copy -t image/gif < "$current_x11_img"
                cp "$current_x11_img" "$last_x11_img"
                log_sync "x11->wl" "Image" " (image/gif)"
            fi
            handled=true
        # Rich text
        elif [ -z "$handled" ] && printf '%s' "$x11_targets" | grep -q 'text/html'; then
            html=$(xclip -selection clipboard -t text/html -o 2>/dev/null || true)
            if [ -n "$html" ]; then
                current_html=$(wl-paste --type text/html 2>/dev/null || true)
                if [ "$html" != "$current_html" ]; then
                    printf '%s' "$html" | wl-copy --type text/html
                    log_sync "x11->wl" "Rich Text" " (text/html)"
                fi
            fi
            handled=true
        # URI list
        elif [ -z "$handled" ] && printf '%s' "$x11_targets" | grep -q 'text/uri-list'; then
            uris=$(xclip -selection clipboard -t text/uri-list -o 2>/dev/null || true)
            if [ -n "$uris" ]; then
                current_uris=$(wl-paste --type text/uri-list 2>/dev/null || true)
                if [ "$uris" != "$current_uris" ]; then
                    printf '%s' "$uris" | wl-copy --type text/uri-list
                    log_sync "x11->wl" "URI List" " (text/uri-list)"
                fi
            fi
            handled=true
        fi

        # Text fallback
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

        # Warn about unhandled types (only if clipboard not empty)
        if [ "$handled" = false ] && [ -n "$x11_targets" ]; then
            log_warn "Unhandled X11 targets: $x11_targets"
        fi

        # rm -f "$LOCK_FILE"
    done
}

log "Clipboard sync service started"
log "Monitoring Wayland ↔ X11 clipboard sync..."

clipboard_sync
