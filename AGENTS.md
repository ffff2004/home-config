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

Prefer source-link config files by `localLib.mkSymlinkToSource`.
For large config trees (for example fcitx5), follow existing patterns
that map files with `localLib.lsFileRecursively` and
`localLib.mkSymlinkToSource`.

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

## Testing Guidelines

```bash
# package
nix build .#<pkg-name>
```

```bash
# config
nix eval .#homeConfigurations.fym.config.<attr-path>
home-manager build
home-manager build --option substitute false
```

This repository has no separate repository-wide unit-test suite, but
some Nix derivations run self-checks during the build.
When adding or changing packages under `pkgs/`,
prefer defining package-specific checks in the derivation itself,
using standard Nixpkgs check mechanisms where appropriate.
Then build the changed package with `nix build .#<pkg-name>`.
Then verify the artifacts in `result/` explicitly.

After changing home-manager config, start with the `nix-eval` skill to do
fast, read-only checks of syntax, affected flake attribute paths, and
final option values.
After that passes, run `home-manager build` as the main validation step.
Use `home-manager build --option substitute false` when you only changed
local configuration and want to skip binary cache substitute lookups for
a faster build; if the change adds packages or new build dependencies,
prefer `home-manager build` so substitutes remain available and
we don't build the dependencies locally.
If the change affects generated files,
like config files (dotfiles), services, etc.,
use the `home-manager-generated-paths` skill to map and
verify the relevant outputs in `result/` explicitly.

## Commit Guidelines

Use commit messages in the form `<type>(<scope>): <summary>`, for
example `fix(gui/umu): use the correct Intel Vulkan ICD path`. Common
types are `feat`, `fix`, `refactor`, `docs`, `chore`, and `agents`; use
`agents` for agent-related files such as skills and `AGENTS.md`. Prefer
stable scopes that match the tree, such as `common/nodejs`, `gui/niri`,
or `lib/ls`.
