# Repository Guidelines

## Project Structure & Module Organization

This repository manages a Home Manager configuration with a flake-based,
modular layout. `flake.nix` defines `homeConfigurations.fym` and injects
`localLib` helpers. Main configuration modules live under `config/`:
`config/common` covers shell, Git, Nix, editors, and CLI tools;
`config/gui` covers desktop, terminal, Niri, Noctalia, and UMU app wrappers.
Shared helper functions live in `lib/`, reusable Home Manager modules
(usually contain options) live in `modules/`, and repo-local packaged
tools live in `pkgs/`.

## Editing Guidelines

Prefer adding a `default.nix` in new directories and importing submodules
through `imports = localLib.lsSubmodule ./.` rather than manually
enumerating files.

`README.md` contains a high-level index of the repository's main Nix
modules, not a complete file list. Update `README.md` when a change adds,
removes, moves, or renames one of these indexed units:

- a direct `config/common/*` or `config/gui/*` feature module, including
  either `*.nix` files or feature directories with `default.nix`;
- a top-level reusable helper under `lib/*.nix`;
- an exported package directory under `pkgs/*/default.nix`;
- a reusable Home Manager module under `modules/`, if one is added later.

Do not add `README.md` entries for implementation details inside an
indexed feature, such as `settings/`, `apps/`, package scripts,
source-linked config files, generated files, or Codex runtime/cache files.

Prefer source-link config files by `localLib.mkSymlinkToSource`.
For large config trees (for example fcitx5), follow existing patterns
that map files with `localLib.mkSymlinkToSourceRecursively target path`.

Use the `home-manager-docs` skill before adding or changing unfamiliar
Home Manager options, so option names, types, defaults, and declarations
match the pinned input.

When this repository is evaluated as a Git flake, untracked files are
not included in the flake source.
If you add a new file and Nix cannot see it, `git add` it first,
but don't commit unrelated changes.

## Coding Style & Naming Conventions

Nix files follow `.editorconfig`: 2-space indentation, LF endings,
UTF-8, trimmed trailing whitespace, and a final newline. Match the
existing naming style: area-based paths such as
`config/common/git.nix`, `config/gui/niri/settings/apps/firefox.nix`,
or `lib/to-source-path.nix`.

Run `nixfmt EDITED_FILES...` after editing files.

## Testing Guidelines

```bash
# package
nix build .#<pkg-name>
```

```bash
# config
nix eval '.#homeConfigurations."<profile>".config.<attr-path>'
nix build '.#homeConfigurations."<profile>".activationPackage' \
  --out-link /tmp/home-manager-builds/<profile>
```

This repository has no separate repository-wide unit-test suite, but
some Nix derivations run self-checks during the build.
When adding or changing packages under `pkgs/`,
prefer defining package-specific checks in the derivation itself,
using standard Nixpkgs check mechanisms where appropriate.
Then build the changed package with `nix build .#<pkg-name>`.
Then verify the artifacts in `result/` explicitly.

After changing Home Manager configuration, use the `nix-eval` skill to
identify candidate and affected profiles and verify their narrow final
option values. Evaluate every candidate profile, but build only affected
profiles.

Use the `home-manager-generated-paths` skill to build affected
`activationPackage` attributes with profile-specific out-links under
`/tmp/home-manager-builds/<profile>` and verify generated files,
services, packages, or executables there. Do not rely on the shared
repository `result` link for profile artifact inspection.

Use `--option substitute false` when changes only affect local
configuration and add no packages or build dependencies. Keep
substitutes enabled when new dependencies may be required.

## Commit Guidelines

Use commit messages in the form `<type>(<scope>): <summary>`, for
example `fix(gui/umu): use the correct Intel Vulkan ICD path`. Common
types are `feat`, `fix`, `refactor`, `docs`, `chore`, and `agents`; use
`agents` for agent-related files such as skills and `AGENTS.md`. Prefer
stable scopes that match the tree, such as `common/nodejs`, `gui/niri`,
or `lib/ls`.
