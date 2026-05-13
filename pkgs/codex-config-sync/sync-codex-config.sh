#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage:\n'
  printf '  %s status [options]\n' "${0##*/}"
  printf '  %s pull-from-home [options]\n' "${0##*/}"
  printf '  %s push-to-home [options]\n' "${0##*/}"
  printf '  %s activate [options]\n' "${0##*/}"
  printf '\n'
  printf 'Commands:\n'
  printf '  status          Report managed-file drift and unmanaged home-side files.\n'
  printf '  pull-from-home  Sync ~/.codex changes back into the repository.\n'
  printf '  push-to-home    Sync repository config into ~/.codex.\n'
  printf '  activate        Safe push mode for Home Manager activation.\n'
  printf '\n'
  printf 'Options:\n'
  printf '  --write               Apply changes instead of reporting only.\n'
  printf '  --add                 For pull-from-home, add unmanaged candidate files.\n'
  printf '  --delete              Delete missing files on the destination side.\n'
  printf '  --force               For push-to-home, overwrite differing home-side files.\n'
  printf '  --codex-home PATH     Override the home Codex directory.\n'
  printf '  --repo-root PATH      Override the repository root.\n'
  printf '  --config-root PATH    Override the tracked Codex config root.\n'
  printf '  --path GLOB           Restrict work to matching relative paths. Repeatable.\n'
  printf '  -h, --help            Show this help.\n'
}

die() {
  printf '%s\n' "$*" >&2
  exit 2
}

command_name="${1:-}"
if [[ -z "$command_name" ]]; then
  usage >&2
  exit 2
fi
shift

candidate_dirs=(
  "skills"
  "agents"
)
skip_patterns=(
  "skills/.system/*"
)

write_changes=0
allow_add=0
allow_delete=0
force_overwrite=0
codex_home="${CODEX_HOME:-$HOME/.codex}"
repo_root=""
config_root=""
path_filters=()
conflict_count=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)
      write_changes=1
      ;;
    --add)
      allow_add=1
      ;;
    --delete)
      allow_delete=1
      ;;
    --force)
      force_overwrite=1
      ;;
    --codex-home)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --codex-home"
      codex_home="$1"
      ;;
    --repo-root)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --repo-root"
      repo_root="$1"
      ;;
    --config-root)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --config-root"
      config_root="$1"
      ;;
    --path)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --path"
      path_filters+=("$1")
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
  shift
done

case "$command_name" in
  status | pull-from-home | push-to-home | activate)
    ;;
  *)
    die "Unknown command: $command_name"
    ;;
esac

if [[ "$command_name" == "activate" ]]; then
  write_changes=1
fi

case "$command_name" in
  status)
    if (( write_changes || allow_add || allow_delete || force_overwrite )); then
      die "status does not accept write flags"
    fi
    ;;
  pull-from-home)
    if (( force_overwrite )); then
      die "pull-from-home does not accept --force"
    fi
    ;;
  push-to-home)
    if (( allow_add )); then
      die "push-to-home does not accept --add"
    fi
    ;;
  activate)
    if (( allow_add || allow_delete || force_overwrite )); then
      die "activate only supports reporting options and --write"
    fi
    ;;
esac

if [[ -z "$repo_root" ]]; then
  repo_root="$(git rev-parse --show-toplevel)"
fi

if [[ -z "$config_root" ]]; then
  config_root="$repo_root/config/common/codex/config"
fi

home_root="$codex_home"
repo_config_root="$config_root"

if [[ ! -d "$repo_config_root" ]]; then
  printf 'Repository Codex config directory does not exist: %s\n' "$repo_config_root" >&2
  exit 1
fi

if [[ "$command_name" == "status" || "$command_name" == "pull-from-home" ]]; then
  if [[ ! -d "$home_root" ]]; then
    printf 'Home Codex directory does not exist: %s\n' "$home_root" >&2
    exit 1
  fi
fi

if [[ "$command_name" == "push-to-home" || "$command_name" == "activate" ]]; then
  mkdir -p "$home_root"
fi

is_skipped() {
  local relative_path="$1"
  local pattern

  for pattern in "${skip_patterns[@]}"; do
    # Intentionally match configured shell globs such as skills/.system/*.
    # shellcheck disable=SC2254
    case "$relative_path" in
      $pattern)
        return 0
        ;;
    esac
  done

  return 1
}

matches_filters() {
  local relative_path="$1"
  local pattern

  if [[ ${#path_filters[@]} -eq 0 ]]; then
    return 0
  fi

  for pattern in "${path_filters[@]}"; do
    # Intentionally match user-provided shell globs from --path.
    # shellcheck disable=SC2254
    case "$relative_path" in
      $pattern)
        return 0
        ;;
    esac
  done

  return 1
}

is_candidate_path() {
  local relative_path="$1"
  local candidate_dir

  for candidate_dir in "${candidate_dirs[@]}"; do
    case "$relative_path" in
      "$candidate_dir"/*)
        return 0
        ;;
    esac
  done

  return 1
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

delete_file() {
  local target_file="$1"
  rm -f "$target_file"
}

format_action() {
  local enabled="$1"

  if (( enabled )); then
    printf 'write'
  else
    printf 'dry-run'
  fi
}

print_header() {
  printf 'Command: %s\n' "$command_name"
  printf 'Action: %s\n' "$(format_action "$write_changes")"
  printf 'Home: %s\n' "$home_root"
  printf 'Repo: %s\n' "$repo_config_root"
  if [[ ${#path_filters[@]} -gt 0 ]]; then
    printf 'Path filters:\n'
    printf '  %s\n' "${path_filters[@]}"
  fi
  printf '\n'
}

print_conflict_guidance() {
  if (( conflict_count == 0 )); then
    return
  fi

  printf '\nNext steps:\n'
  printf '  From the home-config repo, pull local changes back into git:\n'
  printf '    nix run .#codex-config-sync -- pull-from-home --write\n'
  printf '  From the home-config repo, overwrite local files with the repo version:\n'
  printf '    nix run .#codex-config-sync -- push-to-home --write --force\n'
}

list_repo_files() {
  find "$repo_config_root" -type f -print0 | sort -z
}

list_home_files() {
  find "$home_root" -type f -print0 | sort -z
}

report_skipped_home_candidates() {
  local printed=0
  local source_file
  local relative_path

  if [[ ! -d "$home_root" ]]; then
    return
  fi

  printf 'Skipped home-side files:\n'
  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"$home_root"/}"
    if ! is_skipped "$relative_path"; then
      continue
    fi
    if ! matches_filters "$relative_path"; then
      continue
    fi
    printf '  S %s\n' "$relative_path"
    printed=1
  done < <(list_home_files)

  if (( ! printed )); then
    printf '  none\n'
  fi
}

status_pull_report_and_apply() {
  local mode="$1"
  local printed=0
  local target_file
  local source_file
  local relative_path
  local status

  printf 'Managed files:\n'
  while IFS= read -r -d '' target_file; do
    relative_path="${target_file#"$repo_config_root"/}"

    if is_skipped "$relative_path" || ! matches_filters "$relative_path"; then
      continue
    fi

    source_file="$home_root/$relative_path"
    if [[ ! -f "$source_file" ]]; then
      status='-'
    elif cmp -s "$source_file" "$target_file"; then
      status='='
    else
      status='M'
    fi

    printf '  %s %s\n' "$status" "$relative_path"
    printed=1

    if [[ "$mode" == "pull" && "$status" == "M" && "$write_changes" -eq 1 ]]; then
      copy_file "$source_file" "$target_file"
    elif [[ "$mode" == "pull" && "$status" == "-" && "$write_changes" -eq 1 && "$allow_delete" -eq 1 ]]; then
      delete_file "$target_file"
    fi
  done < <(list_repo_files)

  if (( ! printed )); then
    printf '  none\n'
  fi
}

report_unmanaged_home_candidates() {
  local mode="$1"
  local printed=0
  local source_file
  local target_file
  local relative_path

  printf 'Unmanaged home-side candidates:\n'
  if [[ ! -d "$home_root" ]]; then
    printf '  home directory missing\n'
    return
  fi

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"$home_root"/}"

    if is_skipped "$relative_path"; then
      continue
    fi
    if ! is_candidate_path "$relative_path"; then
      continue
    fi
    if ! matches_filters "$relative_path"; then
      continue
    fi

    target_file="$repo_config_root/$relative_path"
    if [[ ! -e "$target_file" ]]; then
      printf '  + %s\n' "$relative_path"
      printed=1

      if [[ "$mode" == "pull" && "$write_changes" -eq 1 && "$allow_add" -eq 1 ]]; then
        copy_file "$source_file" "$target_file"
      fi
    fi
  done < <(list_home_files)

  if (( ! printed )); then
    printf '  none\n'
  fi
}

push_report_and_apply() {
  local printed=0
  local source_file
  local target_file
  local relative_path
  local status

  printf 'Managed files:\n'
  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"$repo_config_root"/}"

    if is_skipped "$relative_path" || ! matches_filters "$relative_path"; then
      continue
    fi

    target_file="$home_root/$relative_path"
    if [[ ! -f "$target_file" ]]; then
      status='+'
    elif cmp -s "$source_file" "$target_file"; then
      status='='
    else
      status='M'
    fi

    printf '  %s %s\n' "$status" "$relative_path"
    printed=1

    if (( write_changes )); then
      case "$status" in
        +)
          copy_file "$source_file" "$target_file"
          ;;
        M)
          if (( force_overwrite )); then
            copy_file "$source_file" "$target_file"
          else
            printf '  ! not overwriting local file: %s\n' "$relative_path"
            conflict_count=$((conflict_count + 1))
          fi
          ;;
      esac
    fi
  done < <(list_repo_files)

  if (( ! printed )); then
    printf '  none\n'
  fi
}

report_unmanaged_home_files_for_push() {
  local printed=0
  local source_file
  local target_file
  local relative_path

  printf 'Unmanaged home-side files:\n'
  if [[ ! -d "$home_root" ]]; then
    printf '  home directory missing\n'
    return
  fi

  while IFS= read -r -d '' target_file; do
    relative_path="${target_file#"$home_root"/}"

    if is_skipped "$relative_path"; then
      continue
    fi
    if ! is_candidate_path "$relative_path"; then
      continue
    fi
    if ! matches_filters "$relative_path"; then
      continue
    fi

    source_file="$repo_config_root/$relative_path"
    if [[ ! -e "$source_file" ]]; then
      printf '  + %s\n' "$relative_path"
      printed=1

      if (( write_changes && allow_delete )); then
        delete_file "$target_file"
      fi
    fi
  done < <(list_home_files)

  if (( ! printed )); then
    printf '  none\n'
  fi
}

print_skipped_patterns() {
  printf '\nSkipped patterns:\n'
  printf '  %s\n' "${skip_patterns[@]}"
}

print_header

case "$command_name" in
  status)
    status_pull_report_and_apply "status"
    printf '\n'
    report_unmanaged_home_candidates "status"
    printf '\n'
    report_skipped_home_candidates
    ;;
  pull-from-home)
    status_pull_report_and_apply "pull"
    printf '\n'
    report_unmanaged_home_candidates "pull"
    printf '\n'
    report_skipped_home_candidates
    ;;
  push-to-home)
    push_report_and_apply
    printf '\n'
    report_unmanaged_home_files_for_push
    ;;
  activate)
    push_report_and_apply
    ;;
esac

print_skipped_patterns
if [[ "$command_name" == "push-to-home" || "$command_name" == "activate" ]]; then
  print_conflict_guidance
fi
