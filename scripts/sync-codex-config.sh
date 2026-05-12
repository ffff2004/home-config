#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run|--apply]\n' "${0##*/}"
}

mode="dry-run"
candidate_dirs=(
  "skills"
  "agents"
)
skip_patterns=(
  "skills/.system/*"
)

case "${1:-}" in
  "" | "--dry-run")
    ;;
  "--apply")
    mode="apply"
    ;;
  "-h" | "--help")
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

is_skipped() {
  local relative_path="$1"
  local pattern

  for pattern in "${skip_patterns[@]}"; do
    case "$relative_path" in
      $pattern)
        return 0
        ;;
    esac
  done

  return 1
}

repo_root="$(git rev-parse --show-toplevel)"
source_root="${CODEX_HOME:-$HOME/.codex}"
target_root="$repo_root/config/common/codex/config"

if [[ ! -d "$source_root" ]]; then
  printf 'Source Codex directory does not exist: %s\n' "$source_root" >&2
  exit 1
fi

if [[ ! -d "$target_root" ]]; then
  printf 'Repository Codex config directory does not exist: %s\n' "$target_root" >&2
  exit 1
fi

status_for() {
  local source_file="$1"
  local target_file="$2"

  if [[ ! -f "$source_file" ]]; then
    printf '%s' '-'
  elif cmp -s "$source_file" "$target_file"; then
    printf '%s' '='
  else
    printf '%s' 'M'
  fi
}

copy_file() {
  local source_file="$1"
  local target_file="$2"
  local mode_flag

  if [[ -x "$source_file" ]]; then
    mode_flag=755
  else
    mode_flag=644
  fi

  install -Dm"$mode_flag" "$source_file" "$target_file"
}

print_managed_updates() {
  local printed=0
  local relative_path
  local source_file
  local target_file
  local status

  printf 'Managed files:\n'

  while IFS= read -r -d '' target_file; do
    relative_path="${target_file#"$target_root"/}"

    if is_skipped "$relative_path"; then
      continue
    fi

    source_file="$source_root/$relative_path"
    status="$(status_for "$source_file" "$target_file")"
    printf '  %s %s\n' "$status" "$relative_path"
    printed=1

    if [[ "$mode" == "apply" && "$status" == "M" ]]; then
      copy_file "$source_file" "$target_file"
    fi
  done < <(find "$target_root" -type f -print0 | sort -z)

  if [[ "$printed" -eq 0 ]]; then
    printf '  none\n'
  fi
}

print_unmanaged_candidates_for() {
  local relative_dir="$1"
  local source_dir="$source_root/$relative_dir"
  local printed=0
  local relative_path
  local source_file
  local target_file

  printf 'Unmanaged candidates in %s:\n' "$relative_dir"

  if [[ ! -d "$source_dir" ]]; then
    printf '  source directory missing\n'
    return
  fi

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"$source_root"/}"

    if is_skipped "$relative_path"; then
      continue
    fi

    target_file="$target_root/$relative_path"
    if [[ ! -e "$target_file" ]]; then
      printf '  + %s\n' "$relative_path"
      printed=1
    fi
  done < <(find "$source_dir" -type f -print0 | sort -z)

  if [[ "$printed" -eq 0 ]]; then
    printf '  none\n'
  fi
}

printf 'Mode: %s\n' "$mode"
printf 'Source: %s\n' "$source_root"
printf 'Target: %s\n' "$target_root"
printf '\n'

print_managed_updates
for relative_dir in "${candidate_dirs[@]}"; do
  printf '\n'
  print_unmanaged_candidates_for "$relative_dir"
done
printf '\n'
printf 'Skipped patterns:\n'
printf '  %s\n' "${skip_patterns[@]}"
