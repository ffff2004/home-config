# Repository Guidelines

## Project Structure & Module Organization

This repository manages a Home Manager configuration with a flake-based,
modular layout. `flake.nix` defines `homeConfigurations.fym` and injects
`localLib` helpers. Main configuration modules live under `config/`:
`config/common` covers shell, Git, Nix, editors, and CLI tools;
`config/gui` covers desktop, input, Niri, Noctalia, and UMU app wrappers.
Shared helper functions live in `lib/`, reusable Home Manager modules
(usually contain options) live in `modules/`, and repo-local packaged
tools live in `pkgs/`.

Prefer adding a `default.nix` in new directories and importing submodules
through `imports = localLib.lsSubmodule ./.` rather than manually
enumerating files.

Prefer source-link config files by localLib.mkSymlinkToSource. For large
config trees (for example fcitx5 config files), follow existing patterns
that map files with localLib.lsFileRecursively and
localLib.mkSymlinkToSource.

## Build, Test, and Development Commands

Run commands from the repository root:

```bash
home-manager build
home-manager build --option substitute false
home-manager switch -b hmbak
```

Use the `home-manager-docs` skill before adding or changing unfamiliar
Home Manager options, so option names, types, defaults, and declarations
match the pinned input. Use the `nix-eval` skill for read-only evaluation
of flake outputs and final option values. `home-manager build` is the
main validation step, `build --option substitute false` is the faster path
for local-only changes that do not introduce new packages or
dependencies, and `switch -b hmbak` applies the result with a backup.

## Coding Style & Naming Conventions

Nix files follow `.editorconfig`: 2-space indentation, LF endings,
UTF-8, trimmed trailing whitespace, and a final newline. Match the
existing naming style: area-based paths such as
`config/gui/terminal.nix`, `config/gui/niri/settings/apps/firefox.nix`,
or `lib/to-source-path.nix`.

## Testing Guidelines

This repository has no separate repository-wide unit-test suite, but
some Nix derivations run self-checks during the build. When adding or
changing packages under `pkgs/`, prefer defining package-specific
checks in the derivation itself, using standard Nixpkgs check
mechanisms where appropriate. Start with the `nix-eval` skill to do
fast, read-only checks of syntax, affected flake attribute paths, and
final option values. After that passes, run `home-manager build` as the
main validation step. Use
`home-manager build --option substitute false` when you only changed
local configuration and want to skip binary cache substitute lookups for
a faster build; if the change adds packages or new build dependencies,
prefer `home-manager build` so substitutes remain available. If the
change affects generated files, services, desktop entries, wrappers, or
repo-local packages under `pkgs/`, use the
`home-manager-generated-paths` skill to map and verify the relevant
outputs in `result/` explicitly; if behavior changes, confirm on the
target machine with `home-manager switch -b hmbak`.

## Commit & Pull Request Guidelines

Use commit messages in the form `<type>(<scope>): <summary>`, for
example `fix(gui/umu): use the correct Intel Vulkan ICD path`. Common
types are `feat`, `fix`, `refactor`, `docs`, `chore`, and `agents`; use
`agents` for agent-related files such as skills and `AGENTS.md`. Prefer
stable scopes that match the tree, such as `common/nodejs`, `gui/niri`,
or `lib/ls`.

Pull requests should describe the user-visible config change, list the
verification commands you ran, and note any files or services that
require a manual `switch` to validate.
