# Desktop Shell Migration

## Goal

Replace `config/gui/noctalia-shell` with a lightweight desktop shell built from
Waybar, swaync, cliphist, wpaperd, and standalone matugen.

## Migration checklist

- [x] Add `config/gui/desktop-shell` no-op skeleton.
- [x] Add standalone matugen template layout.
- [x] Validate kept templates with standalone matugen.
- [x] Add manual standalone matugen runner command.
- [ ] Switch consumers to neutral generated theme paths.
  - [ ] Terminal theme.
  - [ ] Fuzzel theme.
  - [ ] Qt theme.
  - [ ] Swaylock theme/config.
  - [ ] GTK theme CSS.
  - [ ] Pywalfox colors.
- [ ] Move template definitions into owning consumer submodules and keep
  `config/gui/desktop-shell/theme/default.nix` as the central registry.
- [ ] Add `wpaperd` wallpaper runtime.
- [ ] Add Waybar configuration.
- [ ] Add swaync notification center.
- [ ] Add cliphist + fuzzel picker.
- [ ] Add/restore `playerctl` media binds.
- [ ] Disable/remove Noctalia runtime/config.
- [ ] Remove Noctalia-specific swayidle integration.
- [ ] Remove Noctalia flake input/cache after no references remain.

## Completed Steps

1. Added the no-op `config/gui/desktop-shell/default.nix` skeleton.
2. Added `config/gui/desktop-shell/theme/` with standalone matugen templates.
3. Added `desktop-shell-apply-theme` as a manual standalone matugen runner,
   backed by a build-time generated matugen config.

## Current Behavior

- No existing consumers are switched.
- Noctalia remains enabled.
- No services, hooks, or runtime behavior have been changed.
- `desktop-shell-apply-theme` is available as a manual command but is not run
  automatically.

## Known Decisions

- Wallpaper runtime will use `wpaperd`.
- Keep matugen targets:
  - alacritty
  - swaylock
  - pywalfox
  - gtk3
  - gtk4
  - qt5ct
  - qt6ct
  - fuzzel
- Restore media key behavior later using `playerctl`.
- Keep `config/gui/wallpaper-fetcher.nix` separate; it only downloads wallpapers.
- Generate the fuzzel matugen theme at
  `~/.config/fuzzel/themes/matugen.ini`; a future fuzzel config should include
  it with `include=~/.config/fuzzel/themes/matugen.ini`.
- Store matugen `outputPath` values as absolute paths based on Home Manager's
  XDG base directories, such as `config.xdg.configHome` and
  `config.xdg.cacheHome`, instead of relying on matugen to expand `~/...`.
- Generate the matugen config at build time and expose both it and the manual
  runner through readonly theme options for later modules such as `wpaperd`:
  `local.gui.desktopShell.theme.matugenConfig` and
  `local.gui.desktopShell.theme.applyThemeCommand`.

## Module Structure Direction

After the desktop-shell submodules are implemented, move each template
definition next to its owning consumer module. Keep
`config/gui/desktop-shell/theme/default.nix` as the central registry that
collects and exposes template entries, rather than as the long-term owner of
all template definitions.
Consumer modules should register entries under
`local.gui.desktopShell.theme.templates`.

## Validation Already Done

- Templates rendered successfully with matugen 4.0.0 into `/tmp`.
- Generated pywalfox JSON passed `jq empty`.
- Generated alacritty TOML passed `builtins.fromTOML`.
- Home Manager activation package build passed with `--option substitute false`.
- `desktop-shell-apply-theme` rendered all theme targets into a temporary HOME
  using `/home/fym/Pictures/Wallpapers/20260528_.jpg`.
- After switching template `outputPath` values to absolute paths, the generated
  matugen config passed `matugen image --dry-run` with the same wallpaper.

## Next Recommended Step

Switch consumers to the neutral generated theme paths without removing
Noctalia yet.
