# Desktop Shell Migration

## Goal

Replace `config/gui/noctalia-shell` with a lightweight desktop shell built from
Waybar, swaync, cliphist, wpaperd, and standalone matugen.

## Migration checklist

- [x] Add `config/gui/desktop-shell` no-op skeleton.
- [x] Add standalone matugen template layout.
- [x] Validate kept templates with standalone matugen.
- [x] Add manual standalone matugen runner command.
- [x] Switch consumers to neutral generated theme paths.
  - [x] Terminal theme.
  - [x] Fuzzel theme.
  - [x] Qt theme.
  - [x] Swaylock theme/config.
  - [x] GTK theme CSS.
- [x] Pywalfox colors.
- [x] Move template definitions into owning consumer submodules and keep
  `config/gui/desktop-shell/theme/default.nix` as the central registry.
- [x] Add `wpaperd` wallpaper runtime.
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
4. Added `config/gui/desktop-shell/fuzzel/`, moved the fuzzel matugen template
   into that consumer module, and let Home Manager manage
   `~/.config/fuzzel/fuzzel.ini`.
5. Converted `config/gui/terminal.nix` to `config/gui/terminal/`, moved the
   Alacritty matugen template into that consumer module, and pointed Alacritty at
   `~/.config/alacritty/themes/matugen.toml`.
6. Converted `config/gui/qt6ct.nix` to `config/gui/qt6ct/`, moved the qtct
   matugen template into that consumer module, and pointed qt5ct/qt6ct settings
   at generated `matugen.conf` color schemes.
7. Added `config/gui/gtk/`, moved the GTK matugen templates into that consumer
   module, and made GTK3/GTK4 CSS import the generated matugen CSS files.
8. Converted `config/gui/lock-session.nix` to `config/gui/lock-session/`,
   moved the swaylock matugen template into that module, and made the lock
   wrapper use the generated config when it exists.
9. Added `config/gui/pywalfox/`, moved the pywalfox matugen template into that
   module, and installed `pywalfox-native` independently of Noctalia.
10. Added `config/gui/desktop-shell/wpaperd/` as the wallpaper runtime using
    Home Manager's `services.wpaperd` module.

## Current Behavior

- Fuzzel now consumes the neutral generated theme path through a managed
  `~/.config/fuzzel/fuzzel.ini` include.
- Alacritty now imports the neutral generated theme path
  `~/.config/alacritty/themes/matugen.toml`.
- Qt5/Qt6 ct settings now point at generated neutral color schemes under
  `~/.config/qt5ct/colors/matugen.conf` and
  `~/.config/qt6ct/colors/matugen.conf`.
- GTK3/GTK4 CSS now imports generated neutral CSS under
  `~/.config/gtk-3.0/matugen.css` and `~/.config/gtk-4.0/matugen.css`.
- `lock-session` uses `~/.config/swaylock/themes/matugen.conf` when that file
  exists, and falls back to default swaylock behavior otherwise.
- Pywalfox generates neutral colors at `~/.cache/wal/colors-matugen.json`, then
  its post hook copies that file to pywalfox's expected
  `~/.cache/wal/colors.json` before running `pywalfox`.
- `wpaperd` is enabled as the wallpaper runtime and reads wallpapers from
  `/home/fym/Pictures/Wallpapers`.
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
  `~/.config/fuzzel/themes/matugen.ini`; the managed fuzzel config includes it
  with an absolute path derived from `config.xdg.configHome`.
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

Switch another consumer to the neutral generated theme paths without removing
Noctalia yet.
