# Repository Guidelines

## Project Structure & Module Organization

This repository manages a Home Manager configuration with a flake-based, modular layout. `flake.nix` defines `homeConfigurations.fym` and injects `localLib` helpers. Main configuration modules live under `config/`: `config/common` covers shell, Git, Nix, editors, and CLI tools; `config/gui` covers desktop, input, Niri, Noctalia, and UMU app wrappers. Shared helper functions live in `lib/`, and reusable Home Manager modules live in `modules/`.

Prefer adding a `default.nix` in new directories and importing submodules through `imports = localLib.lsSubmodule ./.` rather than manually enumerating files.

Prefer source-link config files by localLib.mkSymlinkToSource. For large config trees (for example fcitx5 config files), follow existing patterns that map files with localLib.lsFileRecursively and localLib.mkSymlinkToSource.

## Build, Test, and Development Commands

Run commands from the repository root:

```bash
home-manager build
home-manager build --option substitute false
home-manager switch -b hmbak
```

Use the `nix-eval` skill for read-only evaluation of flake outputs and final option values. `home-manager build` is the main validation step, `build --option substitute false` is the faster path for local-only changes, and `switch -b hmbak` applies the result with a backup.

## Coding Style & Naming Conventions

Nix files follow `.editorconfig`: 2-space indentation, LF endings, UTF-8, trimmed trailing whitespace, and a final newline. Match the existing naming style: area-based paths such as `config/gui/terminal.nix`, `config/gui/niri/settings/apps/firefox.nix`, or `lib/to-source-path.nix`.

Keep modules focused. Put generic helpers in `lib/`, Home Manager options in `modules/`, and user-facing configuration in `config/`.

## Testing Guidelines

There is no separate unit-test suite in this repository. Start with the `nix-eval` skill to do fast, read-only checks of syntax, affected flake attribute paths, and final option values. After that passes, run `home-manager build` as the main validation step. Use `home-manager build --option substitute false` when you only changed local configuration and want to skip binary cache substitute lookups for a faster build. If the change affects generated files, services, desktop entries, or wrappers, verify those outputs in `result/` explicitly; if behavior changes, confirm on the target machine with `home-manager switch -b hmbak`.

## Commit & Pull Request Guidelines

Use commit messages in the form `<type>(<scope>): <summary>`, for example `fix(gui/umu): use the correct Intel Vulkan ICD path`. Common types are `feat`, `fix`, `refactor`, `docs`, and `chore`. Prefer stable scopes that match the tree, such as `common/nodejs`, `gui/niri`, or `lib/ls`.

Pull requests should describe the user-visible config change, list the verification commands you ran, and note any files or services that require a manual `switch` to validate.
