---
name: home-manager-generated-paths
description: Map files produced by a Home Manager build to their relative paths under result/home-files or result/home-path. Use this when answering where an option lands, what files exist in the build result, or how a home-directory path maps back to result.
---

# Home Manager Generated Paths

Use this skill to map files produced by a Home Manager build into a readable form:

`home path -> relative path under result -> source option`

## When To Use

Use this when the user wants to know:

- Where a config file will appear after `home-manager build`
- How a home-directory path maps to `result/home-files` or `result/home-path`
- Which files are produced by `home.file`, `xdg.configFile`, `xdg.dataFile`, or user systemd units
- Which Home Manager option produced a path under `result`

## Core Rules

- `home.file`, `xdg.configFile`, and `xdg.dataFile` usually generate files under `result/home-files/...`
- Installed packages, profile resources, executables, desktop files, icons, man pages, and shared resources usually come from `result/home-path/...`
- User systemd units should be checked separately through Home Manager's systemd output
- Inside Home Manager, config is merged: systemd.user.*.* -> xdg.*File.* -> home.file.*
- `result` is usually a symlink to a Home Manager generation. When answering about concrete files, prefer paths relative to `result/home-files` or `result/home-path`
- Nix attribute names (e.g., `xdg.configFile.niri-config`) may not correspond to generated file paths under `result`, always check the actual path config `<file-attr>.target`.

## Workflow

1. Inspect evaluated Home Manager options first, especially `config.home.file`, `config.xdg.configFile`, `config.xdg.dataFile`, and relevant `config.systemd.user.*` values.
2. If the actual file tree needs to be verified, run or reuse `home-manager build`, then confirm where `result` points.
3. Check the real paths under `result/home-files` and `result/home-path`. For symlinks, directories, or duplicate-looking entries, verify the file tree and link targets before answering.
4. Report the home path, the relative path under `result`, and the source option when it can be identified.
5. If there are many entries, group them by area, such as top-level files, `.config`, `.local/share`, `.gnupg`, and user systemd units.

## Output Format

Prefer this shape:

- Home path: `~/.config/example/config.toml`
- Result path: `result/home-files/.config/example/config.toml`
- Source: `xdg.configFile."example/config.toml"`

For larger answers, group entries by directory or subsystem.

## Final Checks

Before answering, confirm that:

- Listed paths come from evaluated options or the actual build tree
- `result/home-files` and `result/home-path` are not mixed up
- Symlinks, directories, and duplicate-looking paths have been verified
- Nix attribute names are not presented as final generated paths
