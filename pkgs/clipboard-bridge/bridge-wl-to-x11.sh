LOCK_FILE="/tmp/clipboard_bridge_lock"

if [ -t 1 ]; then
    COLOR_RESET='\033[0m'
    COLOR_GREEN='\033[32m'
    COLOR_YELLOW='\033[33m'
    COLOR_CYAN='\033[36m'
    COLOR_RED='\033[31m'
else
    COLOR_RESET=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_CYAN=''
    COLOR_RED=''
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

# 单例检查 + 陈旧锁清理
if [ -e "$LOCK_FILE" ]; then
    if kill -0 $(cat "$LOCK_FILE" 2>/dev/null) 2>/dev/null || grep "x11" "$LOCK_FILE" >/dev/null 2>&1; then
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

# 写入当前 PID 并设置清理
printf '%d\n' "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

types=$(wl-paste --list-types 2>/dev/null)
synced=false

# Handle known types
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

# Fallback to plain text if nothing handled yet and content exists
if [ "$synced" = false ]; then
    # Check if there's at least plain text
    if wl-paste --type text/plain >/dev/null 2>&1; then
        text=$(wl-paste --type text/plain 2>/dev/null || true)
        if [ -n "$text" ]; then
            printf '%s' "$text" | xclip -selection clipboard
            preview="${text%%$'\n'*}"
            preview="${preview:0:50}"
            preview="${preview//$'\n'/↵}"
            preview="${preview//$'\r'/}"
            preview="${preview//$'\\t'/⇥}"
            [ "${#text}" -gt 50 ] && preview="$preview..."
            log_sync "Text" " \"$preview\""
            synced=true
        fi
    fi
fi

# Warn about unhandled non-empty types
if [ "$synced" = false ] && [ -n "$types" ]; then
    log_warn "$types"
fi

sleep 0.1
rm -f "$LOCK_FILE"
