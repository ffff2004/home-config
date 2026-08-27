#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
main_commit=$(git -C "$repo_root" rev-parse HEAD)
main_date=$(git -C "$repo_root" show -s --format=%cs "$main_commit")
main_date=${main_date//-/}
main_tag=$(git -C "$repo_root" describe --tags --exact-match "$main_commit" 2>/dev/null || true)
main_ref=${main_tag:-${main_commit:0:8}}
main_ref=${main_ref//\//-}

archive_prefix=$(basename "$repo_root")
archive_base="${archive_prefix}-${main_date}-${main_ref}"
archive_path="/tmp/$archive_base.tar.gz"

git -C "$repo_root" archive \
    --format=tar.gz \
    --prefix="$archive_prefix/" \
    --output="$archive_path" \
    "$main_commit"

echo "$archive_path"
