#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage:\n'
  printf '  %s daemon\n' "${0##*/}"
  printf '  %s watch wl-to-x11|x11-to-wl\n' "${0##*/}"
  printf '  %s sync-once wl-to-x11|x11-to-wl\n' "${0##*/}"
  printf '  %s status\n' "${0##*/}"
  printf '\n'
  printf 'Commands:\n'
  printf '  daemon       Run both clipboard bridge watchers.\n'
  printf '  watch        Run one directional watcher.\n'
  printf '  sync-once    Copy the current source clipboard to the other side.\n'
  printf '  status       Report daemon and watcher lock state.\n'
}

die() {
  printf 'clipboard-bridge: %s\n' "$*" >&2
  exit 2
}

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

runtime_root="/tmp"
if [[ -n "${XDG_RUNTIME_DIR:-}" && -w "${XDG_RUNTIME_DIR:-}" ]]; then
  runtime_root="$XDG_RUNTIME_DIR"
fi

state_dir="$runtime_root/clipboard-bridge"
self="${BASH_SOURCE[0]}"
locks=()
children=()

init_state_dir() {
  mkdir -p "$state_dir"
  chmod 700 "$state_dir" 2>/dev/null || true
}

require_commands() {
  local command_name

  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 || die "missing dependency: $command_name"
  done
}

lock_pid_is_alive() {
  local lock_dir="$1"
  local pid=""

  if [[ -r "$lock_dir/pid" ]]; then
    read -r pid < "$lock_dir/pid" || true
  fi

  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

acquire_process_lock() {
  local name="$1"
  local lock_dir="$state_dir/$name.lock"

  while ! mkdir "$lock_dir" 2>/dev/null; do
    if lock_pid_is_alive "$lock_dir"; then
      log "$name is already running"
      exit 0
    fi
    rm -rf "$lock_dir"
  done

  printf '%d\n' "$$" > "$lock_dir/pid"
  locks+=("$lock_dir")
}

cleanup() {
  local pid
  local lock_dir

  for pid in "${children[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done

  for lock_dir in "${locks[@]}"; do
    rm -rf "$lock_dir"
  done
}

trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

validate_direction() {
  case "${1:-}" in
    wl-to-x11 | x11-to-wl)
      ;;
    *)
      die "expected direction: wl-to-x11 or x11-to-wl"
      ;;
  esac
}

list_wl_types() {
  wl-paste --list-types 2>/dev/null || true
}

list_x11_types() {
  xclip -selection clipboard -t TARGETS -o 2>/dev/null || true
}

type_list_has() {
  local types="$1"
  local candidate="$2"

  printf '%s\n' "$types" | grep -Fxq -- "$candidate"
}

choose_source_type() {
  local direction="$1"
  local types="$2"
  local candidate
  local line
  local priorities=()

  case "$direction" in
    wl-to-x11)
      priorities=(
        image/png
        image/jpeg
        image/gif
        text/html
        text/uri-list
        "text/plain;charset=utf-8"
        text/plain
      )
      ;;
    x11-to-wl)
      priorities=(
        image/png
        image/jpeg
        image/gif
        text/html
        text/uri-list
        "text/plain;charset=utf-8"
        text/plain
        UTF8_STRING
        STRING
        TEXT
      )
      ;;
  esac

  for candidate in "${priorities[@]}"; do
    if type_list_has "$types" "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  while IFS= read -r line; do
    case "$line" in
      text/plain*)
        printf '%s\n' "$line"
        return 0
        ;;
    esac
  done <<< "$types"

  return 1
}

is_plain_text_type() {
  case "$1" in
    text/plain | text/plain\;* | UTF8_STRING | STRING | TEXT)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

destination_type() {
  local direction="$1"
  local source_type="$2"

  case "$direction" in
    wl-to-x11)
      if is_plain_text_type "$source_type"; then
        printf 'UTF8_STRING\n'
      else
        printf '%s\n' "$source_type"
      fi
      ;;
    x11-to-wl)
      if is_plain_text_type "$source_type"; then
        printf 'text/plain;charset=utf-8\n'
      else
        printf '%s\n' "$source_type"
      fi
      ;;
  esac
}

read_wl_payload() {
  local mime_type="$1"
  local output_path="$2"

  wl-paste --type "$mime_type" > "$output_path" 2>/dev/null
}

read_x11_payload() {
  local mime_type="$1"
  local output_path="$2"

  if xclip -selection clipboard -t "$mime_type" -o > "$output_path" 2>/dev/null; then
    return 0
  fi

  if is_plain_text_type "$mime_type"; then
    xclip -selection clipboard -o > "$output_path" 2>/dev/null
    return $?
  fi

  return 1
}

read_source_payload() {
  local direction="$1"
  local mime_type="$2"
  local output_path="$3"

  case "$direction" in
    wl-to-x11)
      read_wl_payload "$mime_type" "$output_path"
      ;;
    x11-to-wl)
      read_x11_payload "$mime_type" "$output_path"
      ;;
  esac
}

read_destination_payload() {
  local direction="$1"
  local mime_type="$2"
  local output_path="$3"

  case "$direction" in
    wl-to-x11)
      read_x11_payload "$mime_type" "$output_path"
      ;;
    x11-to-wl)
      read_wl_payload "$mime_type" "$output_path"
      ;;
  esac
}

write_wl_payload() {
  local mime_type="$1"
  local input_path="$2"

  wl-copy --type "$mime_type" < "$input_path"
}

write_x11_payload() {
  local mime_type="$1"
  local input_path="$2"

  if is_plain_text_type "$mime_type"; then
    xclip -selection clipboard < "$input_path"
  else
    xclip -selection clipboard -t "$mime_type" < "$input_path"
  fi
}

write_destination_payload() {
  local direction="$1"
  local mime_type="$2"
  local input_path="$3"

  case "$direction" in
    wl-to-x11)
      write_x11_payload "$mime_type" "$input_path"
      ;;
    x11-to-wl)
      write_wl_payload "$mime_type" "$input_path"
      ;;
  esac
}

sync_once() {
  local direction="$1"
  local tmp_dir
  local source_types
  local source_type
  local dest_type
  local source_file
  local dest_file

  validate_direction "$direction"
  require_commands cmp grep mktemp xclip wl-copy wl-paste
  init_state_dir

  tmp_dir=$(mktemp -d --tmpdir="$state_dir" sync.XXXXXX)
  source_file="$tmp_dir/source"
  dest_file="$tmp_dir/dest"

  case "$direction" in
    wl-to-x11)
      source_types=$(list_wl_types)
      ;;
    x11-to-wl)
      source_types=$(list_x11_types)
      ;;
  esac

  if ! source_type=$(choose_source_type "$direction" "$source_types"); then
    [[ -n "$source_types" ]] && log "$direction: unsupported clipboard types: ${source_types//$'\n'/, }"
    rm -rf "$tmp_dir"
    return 0
  fi

  dest_type=$(destination_type "$direction" "$source_type")

  if ! read_source_payload "$direction" "$source_type" "$source_file"; then
    log "$direction: failed to read $source_type"
    rm -rf "$tmp_dir"
    return 0
  fi

  if read_destination_payload "$direction" "$dest_type" "$dest_file" && cmp -s "$source_file" "$dest_file"; then
    rm -rf "$tmp_dir"
    return 0
  fi

  if write_destination_payload "$direction" "$dest_type" "$source_file"; then
    log "$direction: synced $source_type"
  else
    log "$direction: failed to write $dest_type"
  fi

  rm -rf "$tmp_dir"
}

watch_wl_to_x11() {
  require_commands grep mkdir rm xclip wl-paste
  init_state_dir
  acquire_process_lock "watch-wl-to-x11"

  log "watching Wayland clipboard"
  sync_once wl-to-x11 || true
  wl-paste --watch "$self" sync-once wl-to-x11
}

watch_x11_to_wl() {
  require_commands clipnotify grep mkdir rm sleep xclip wl-copy wl-paste
  init_state_dir
  acquire_process_lock "watch-x11-to-wl"

  log "watching X11 clipboard"
  sync_once x11-to-wl || true

  while clipnotify; do
    sleep 0.05
    sync_once x11-to-wl || true
  done
}

daemon() {
  local status

  require_commands clipnotify grep mkdir rm sleep xclip wl-copy wl-paste
  init_state_dir
  acquire_process_lock daemon

  "$self" watch wl-to-x11 &
  children+=("$!")
  "$self" watch x11-to-wl &
  children+=("$!")

  log "daemon started"
  wait -n "${children[@]}"
  status=$?
  return "$status"
}

status() {
  local name
  local lock_dir

  init_state_dir
  for name in daemon watch-wl-to-x11 watch-x11-to-wl; do
    lock_dir="$state_dir/$name.lock"
    if [[ ! -d "$lock_dir" ]]; then
      printf '%s: stopped\n' "$name"
    elif lock_pid_is_alive "$lock_dir"; then
      printf '%s: running\n' "$name"
    else
      printf '%s: stale lock\n' "$name"
    fi
  done
}

main() {
  local command_name="${1:-}"

  case "$command_name" in
    -h | --help)
      usage
      ;;
    daemon)
      shift
      [[ $# -eq 0 ]] || die "daemon takes no arguments"
      daemon
      ;;
    watch)
      shift
      [[ $# -eq 1 ]] || die "watch expects one direction"
      validate_direction "$1"
      case "$1" in
        wl-to-x11)
          watch_wl_to_x11
          ;;
        x11-to-wl)
          watch_x11_to_wl
          ;;
      esac
      ;;
    sync-once)
      shift
      [[ $# -eq 1 ]] || die "sync-once expects one direction"
      sync_once "$1"
      ;;
    status)
      shift
      [[ $# -eq 0 ]] || die "status takes no arguments"
      status
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
