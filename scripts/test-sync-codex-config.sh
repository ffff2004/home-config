#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sync_script="$script_dir/sync-codex-config.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_equals() {
  local path="$1"
  local expected="$2"
  local actual

  actual="$(<"$path")"
  if [[ "$actual" != "$expected" ]]; then
    fail "expected $path to equal [$expected], got [$actual]"
  fi
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "expected path to exist: $path"
}

assert_missing() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be missing: $path"
}

assert_output_contains() {
  local output="$1"
  local needle="$2"

  if ! grep -Fq -- "$needle" <<<"$output"; then
    fail "expected output to contain: $needle"
  fi
}

new_case() {
  local name="$1"

  case_root="$tmpdir/$name"
  repo_root="$case_root/repo"
  home_root="$case_root/home"

  mkdir -p "$repo_root" "$home_root"
}

write_file() {
  local path="$1"
  local content="$2"

  mkdir -p "$(dirname "$path")"
  printf '%b' "$content" > "$path"
}

run_sync() {
  "$sync_script" "$@" --repo-root "$repo_root" --config-root "$repo_root" --codex-home "$home_root"
}

test_status_reports_expected_markers() {
  new_case status
  write_file "$repo_root/AGENTS.md" "same\n"
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$repo_root/agents/demo.toml" "repo-agent\n"
  write_file "$home_root/AGENTS.md" "same\n"
  write_file "$home_root/skills/demo/SKILL.md" "home-skill\n"
  write_file "$home_root/skills/extra/new.md" "new-home\n"
  write_file "$home_root/skills/.system/hidden.md" "skip\n"
  write_file "$home_root/misc/ignored.txt" "ignore\n"

  local output
  output="$(run_sync status)"

  assert_output_contains "$output" "  = AGENTS.md"
  assert_output_contains "$output" "  M skills/demo/SKILL.md"
  assert_output_contains "$output" "  - agents/demo.toml"
  assert_output_contains "$output" "  + skills/extra/new.md"
  assert_output_contains "$output" "  S skills/.system/hidden.md"
  if grep -Fq "misc/ignored.txt" <<<"$output"; then
    fail "status should not report non-candidate unmanaged files"
  fi
}

test_pull_from_home_updates_managed_files() {
  new_case pull_write
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/demo/SKILL.md" "home-skill\n"

  run_sync pull-from-home --write >/dev/null

  assert_file_equals "$repo_root/skills/demo/SKILL.md" "home-skill"
}

test_pull_from_home_adds_candidates() {
  new_case pull_add
  write_file "$home_root/skills/extra/new.md" "new-home\n"
  write_file "$home_root/misc/ignored.txt" "ignore\n"

  run_sync pull-from-home --write --add >/dev/null

  assert_file_equals "$repo_root/skills/extra/new.md" "new-home"
  assert_missing "$repo_root/misc/ignored.txt"
}

test_push_to_home_write_is_conservative() {
  new_case push_safe
  write_file "$repo_root/AGENTS.md" "repo-agents\n"
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/demo/SKILL.md" "home-skill\n"

  local output
  output="$(run_sync push-to-home --write)"

  assert_exists "$home_root/AGENTS.md"
  assert_file_equals "$home_root/AGENTS.md" "repo-agents"
  assert_file_equals "$home_root/skills/demo/SKILL.md" "home-skill"
  assert_output_contains "$output" "  ! not overwriting local file: skills/demo/SKILL.md"
}

test_push_to_home_force_overwrites_conflicts() {
  new_case push_force
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/demo/SKILL.md" "home-skill\n"

  run_sync push-to-home --write --force >/dev/null

  assert_file_equals "$home_root/skills/demo/SKILL.md" "repo-skill"
}

test_activate_matches_safe_push_behavior() {
  new_case activate
  write_file "$repo_root/AGENTS.md" "repo-agents\n"
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/demo/SKILL.md" "home-skill\n"

  local output
  output="$(run_sync activate)"

  assert_exists "$home_root/AGENTS.md"
  assert_file_equals "$home_root/AGENTS.md" "repo-agents"
  assert_file_equals "$home_root/skills/demo/SKILL.md" "home-skill"
  assert_output_contains "$output" "Action: write"
  assert_output_contains "$output" "  ! not overwriting local file: skills/demo/SKILL.md"
}

test_push_to_home_delete_removes_managed_extras_only() {
  new_case push_delete
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$home_root/skills/extra/new.md" "new-home\n"
  write_file "$home_root/misc/ignored.txt" "ignore\n"

  run_sync push-to-home --write --delete >/dev/null

  assert_missing "$home_root/skills/extra/new.md"
  assert_exists "$home_root/misc/ignored.txt"
}

test_pull_from_home_delete_removes_missing_repo_files() {
  new_case pull_delete
  write_file "$repo_root/skills/demo/SKILL.md" "repo-skill\n"
  write_file "$repo_root/agents/demo.toml" "repo-agent\n"
  write_file "$home_root/skills/demo/SKILL.md" "repo-skill\n"

  run_sync pull-from-home --write --delete >/dev/null

  assert_exists "$repo_root/skills/demo/SKILL.md"
  assert_missing "$repo_root/agents/demo.toml"
}

tests=(
  test_status_reports_expected_markers
  test_pull_from_home_updates_managed_files
  test_pull_from_home_adds_candidates
  test_push_to_home_write_is_conservative
  test_push_to_home_force_overwrites_conflicts
  test_activate_matches_safe_push_behavior
  test_push_to_home_delete_removes_managed_extras_only
  test_pull_from_home_delete_removes_missing_repo_files
)

for test_name in "${tests[@]}"; do
  printf '==> %s\n' "$test_name"
  "$test_name"
done

printf 'All sync-codex-config tests passed.\n'
