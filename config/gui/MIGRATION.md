# GUI Shell Migration

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
  `config/gui/theme/default.nix` as the central registry.
- [x] Add `wpaperd` wallpaper runtime.
- [x] Apply matugen theme generation from wallpaper runtime.
- [x] Add runtime-switchable matugen light/dark mode.
- [x] Restore GTK system appearance mode sync.
- [x] Add Waybar configuration.
- [x] Move the lightweight shell modules out of `config/gui/desktop-shell`
  into direct `config/gui` modules.
- [x] Add swaync notification center.
- [ ] Add cliphist + fuzzel picker.
- [ ] Add/restore `playerctl` media binds.
- [ ] Disable/remove Noctalia runtime/config.
- [ ] Remove Noctalia-specific swayidle integration.
- [ ] Remove Noctalia flake input/cache after no references remain.

## Completed Steps

1. Added the no-op `config/gui/desktop-shell/default.nix` skeleton.
2. Added `config/gui/theme/` with standalone matugen templates.
3. Added `gui-apply-theme` as a manual standalone matugen runner,
   backed by a build-time generated matugen config.
4. Added `config/gui/fuzzel/`, moved the fuzzel matugen template
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
10. Added `config/gui/wpaperd.nix` as the wallpaper runtime using
    Home Manager's `services.wpaperd` module.
11. Wired `wpaperd`'s wallpaper-change `exec` hook to
    `gui-apply-theme`.
12. Added runtime matugen mode switching through
    `gui-theme-mode dark|light|toggle`.
13. Restored the Noctalia GTK mode sync behavior with
    `gui-gtk-sync-mode`, called once from the GTK matugen template
    hooks.
14. Added `config/gui/waybar/` with a bottom Waybar
    configuration, source-linked style/menu files, power/session menu, system
    monitor modules, MPRIS, Niri workspaces, `wlr/taskbar`, tray, clock,
    battery, backlight, and WirePlumber sink/source controls.
15. Removed the `config/gui/desktop-shell` module boundary by moving the active
    modules to direct `config/gui` modules and renaming the Nix option namespace
    from `local.gui.desktopShell.theme` to `local.gui.theme`.
16. Added `config/gui/swaync/` with Home Manager's SwayNC service, a basic
    notification center configuration, source-linked CSS, and a matugen color
    template.

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
- Pywalfox generates colors directly at `~/.cache/wal/colors.json`, then its
  post hook runs `pywalfox`.
- `wpaperd` is enabled as the wallpaper runtime and reads wallpapers from
  `/home/fym/Pictures/Wallpapers`.
- `wpaperd` now runs `gui-apply-theme` when the wallpaper changes.
- `gui-apply-theme` reads the current matugen mode from
  `~/.config/gui/theme/mode`, defaults to `dark` when the file is
  absent, validates that the value is `dark` or `light`, and records the last
  applied wallpaper under `~/.local/state/gui/theme/wallpaper`.
- `gui-theme-mode dark|light|toggle` writes the runtime mode file and
  reapplies the last wallpaper when one has already been recorded.
- GTK matugen generation now syncs `org.gnome.desktop.interface color-scheme`
  through `gsettings`, falling back to `dconf`, and sets `adw-gtk3` /
  `adw-gtk3-dark` as `gtk-theme` when the theme is installed.
- Waybar is enabled in Home Manager, configured as a bottom bar, and started by
  Home Manager's Waybar user systemd service.
- Waybar CSS is source-linked from
  `config/gui/waybar/style.css` and imports the future matugen
  target `~/.config/waybar/themes/matugen.css`.
- Waybar uses `wireplumber` for default output volume and
  `wireplumber#source` for default input volume/mute state. Right-clicking
  either opens `pwvucontrol`.
- SwayNC is enabled as the notification daemon through Home Manager, uses
  source-linked CSS from `config/gui/swaync/style.css`, and imports the
  generated matugen target `~/.config/swaync/themes/matugen.css`.
- Noctalia remains enabled.

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
  - waybar
  - swaync
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
  `local.gui.theme.matugenConfig` and
  `local.gui.theme.applyThemeCommand`.
- Keep the current matugen `dark`/`light` mode as runtime state, not Nix state.
  The mode file lives at `~/.config/gui/theme/mode`, so switching mode
  does not require `home-manager switch`.
- Runtime command names and state paths have moved to the `gui` namespace:
  `gui-apply-theme`, `gui-theme-mode`, and `~/.config/gui/theme/mode`. Old
  `desktop-shell` runtime state is intentionally not migrated.

## Module Structure Direction

Keep each template definition next to its owning consumer module. Keep
`config/gui/theme/default.nix` as the central registry that collects and exposes
template entries, rather than as the owner of all template definitions.
Consumer modules should register entries under `local.gui.theme.templates`.

## Validation Already Done

- Templates rendered successfully with matugen 4.0.0 into `/tmp`.
- Generated pywalfox JSON passed `jq empty`.
- Generated alacritty TOML passed `builtins.fromTOML`.
- Home Manager activation package build passed with `--option substitute false`.
- `gui-apply-theme` rendered all theme targets into a temporary HOME
  using `/home/fym/Pictures/Wallpapers/20260528_.jpg`.
- After switching template `outputPath` values to absolute paths, the generated
  matugen config passed `matugen image --dry-run` with the same wallpaper.

## Next Recommended Step

Add `config/gui/swaync/` as the notification center without removing Noctalia
yet. Keep the first pass focused on the package, service, basic config, and
theme path strategy; wire Waybar notification interactions in a follow-up once
swaync behavior is verified.
