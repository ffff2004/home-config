# Project Guidelines

## Scope
This workspace manages a Home Manager setup for user fym, centered on flake.nix and modular Nix files under config/, lib/, and modules/.

## Code Style
- Use 2-space indentation in Nix files, matching .editorconfig.
- Keep default.nix files as module entry points that aggregate imports.
- Prefer concise let bindings and inherit for readability when values are already in scope.
- Keep comments short and only for non-obvious behavior.

## Architecture
- Entry point is flake.nix, which defines inputs, localLib, and homeConfigurations.fym.
- Main module graph starts at config/default.nix and modules/default.nix.
- Auto-import behavior is implemented in lib/ls.nix via lsSubmodule; this is a core repository pattern.
- Source-linked config files are handled by localLib.mkSymlinkToSource from lib/to-source-path.nix.
- GUI-specific modules are under config/gui/, while shared modules are under config/common/.

## Build And Validation
- Preferred quick validation before proposing changes: home-manager build.
- When only configuration files are changed (no package additions), prefer: home-manager build --option substitute false.
- The substitute=false option skips querying binary caches and can save validation time for config-only edits.
- Apply changes with backup when requested: home-manager switch -b hmbak.
- Local shell aliases may exist (hmb, hmbo, hms, hmso) in config/common/shell.nix; do not assume aliases are available in non-interactive environments.
- Format Nix changes with nixfmt when available.

## Conventions
- Preserve the recursive import convention:
  - default.nix in module directories usually contains imports = localLib.lsSubmodule ./.
- When adding a new module directory, include a default.nix that participates in the same import pattern.
- Avoid changing home.stateVersion unless explicitly requested.
- Prefer placing shared logic in lib/ and consuming it from modules, instead of duplicating expressions.
- For large generated config trees (for example fcitx5 config files), follow existing patterns that map files with localLib.lsFileRecursively and localLib.mkSymlinkToSource.

## Key References
- flake.nix
- lib/ls.nix
- lib/to-source-path.nix
- config/default.nix
- config/common/shell.nix
- config/common/home-manager.nix
- config/gui/fcitx5/default.nix
- README.md

## Agent Behavior In This Repo
- Make minimal edits that match existing module structure.
- Do not introduce broad refactors unless explicitly asked.
- If a requested change may affect module loading behavior, verify import paths and lsSubmodule implications first.
- Read README.md when a task spans multiple directories, needs module ownership context, or requires quick project orientation; skip it for clear single-file edits.
