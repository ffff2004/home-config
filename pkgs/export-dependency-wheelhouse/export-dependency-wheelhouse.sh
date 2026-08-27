#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
main_commit=$(git -C "$repo_root" rev-parse HEAD)
main_date=$(git -C "$repo_root" show -s --format=%cs "$main_commit")
main_date=${main_date//-/}
main_tag=$(git -C "$repo_root" describe --tags --exact-match "$main_commit" 2>/dev/null || true)
main_ref=${main_tag:-${main_commit:0:8}}
main_ref=${main_ref//\//-}

repo_name=$(basename "$repo_root")
archive_base="${repo_name}-wheelhouse-${main_date}-${main_ref}"
archive_path="/tmp/${archive_base}.tar.zst"

wheelhouse_dir=$(mktemp -d)
verify_env=''

cleanup() {
    rm -rf "$wheelhouse_dir"
    if [[ -n "$verify_env" ]]; then
        rm -rf "$verify_env"
    fi
}
trap cleanup EXIT

requirements_file="$wheelhouse_dir/requirements.txt"

uv export \
    --locked \
    --all-extras \
    --no-editable \
    --no-emit-workspace \
    --no-header \
    --no-annotate \
    --no-hashes \
    --output-file "$requirements_file"

uv run --no-project --with pip python -m pip download \
    --only-binary=:all: \
    --dest "$wheelhouse_dir" \
    --requirement "$requirements_file"

tar --zstd --create --file "$archive_path" --directory "$wheelhouse_dir" .

echo "$archive_path"
