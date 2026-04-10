# Commit Conventions

Use commit messages in the form `<type>(<scope>): <summary>`.

## Types

- `feat`: add a new module, program, service, or user-facing capability
- `fix`: correct broken behavior, invalid paths, wrong conditions, or configuration errors
- `refactor`: reorganize code or modules without changing intended behavior
- `docs`: update README, AGENTS guidance, comments, or other documentation
- `chore`: maintenance changes such as `flake.lock`, editor settings, or `.gitignore`
- `revert`: revert an earlier commit

## Scopes

Prefer stable scopes that match this repository's layout, for example:

- `flake`
- `docs`
- `agents`
- `common/shell`
- `common/nodejs`
- `common/python`
- `common/misc`
- `gui/fcitx5`
- `gui/niri`
- `gui/noctalia-shell`
- `gui/umu`
- `gui/terminal`
- `lib/ls`
- `lib/to-source-path`

Use a broader scope such as `common` or `gui` only when a single change intentionally spans multiple modules in that area.

## Summary Line

- Keep the summary short and outcome-focused.
- Prefer English for consistency.
- Do not end the summary with a period.

## Commit Boundaries

- Keep one logical change per commit.
- Separate unrelated config changes into different commits.
- Keep `flake.lock` updates in their own commit when practical.
- When a module change also requires documentation updates, include both in the same commit if they describe the same logical change.

## Examples

- `feat(gui/desktop-entries): add dingtalk fcitx launcher`
- `fix(common/nodejs): correct npmrc path and global prefix`
- `refactor(common/misc): split nodejs and python into submodules`
- `docs(agents): add doc-sync rule for module-level changes`
- `chore(flake): update lock file`
