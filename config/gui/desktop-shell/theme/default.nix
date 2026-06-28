{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.gui.desktopShell.theme;
  configHome = config.xdg.configHome;
  stateHome = config.xdg.stateHome;

  matugenConfigFormat = pkgs.formats.toml { };

  modePath = "${configHome}/desktop-shell/theme/mode";
  lastWallpaperPath = "${stateHome}/desktop-shell/theme/wallpaper";

  toMatugenTemplate =
    template:
    lib.filterAttrs (_: value: value != null) {
      input_path = toString template.inputPath;
      output_path = template.outputPath;
      pre_hook = template.preHook;
      post_hook = template.postHook;
    };

  matugenConfig = matugenConfigFormat.generate "desktop-shell-matugen.toml" {
    config = lib.optionalAttrs (cfg.customColors != { }) {
      custom_colors = cfg.customColors;
    };
    templates = lib.mapAttrs (_: toMatugenTemplate) cfg.templates;
  };

  applyThemeCommand = pkgs.writeShellApplication {
    name = "desktop-shell-apply-theme";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.matugen
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: desktop-shell-apply-theme WALLPAPER" >&2
        exit 64
      fi

      wallpaper=$1
      if [ ! -f "$wallpaper" ]; then
        echo "desktop-shell-apply-theme: wallpaper not found: $wallpaper" >&2
        exit 66
      fi

      mode=dark
      if [ -f "${modePath}" ]; then
        mode=$(tr -d '[:space:]' < "${modePath}")
      fi

      case "$mode" in
        dark|light)
          ;;
        "")
          mode=dark
          ;;
        *)
          echo "desktop-shell-apply-theme: invalid theme mode in ${modePath}: $mode" >&2
          echo "Expected: dark or light" >&2
          exit 65
          ;;
      esac

      matugen image "$wallpaper" -c "${matugenConfig}" --source-color-index 0 --mode "$mode"

      mkdir -p "$(dirname "${lastWallpaperPath}")"
      printf '%s\n' "$wallpaper" > "${lastWallpaperPath}"
    '';
  };

  themeModeCommand = pkgs.writeShellApplication {
    name = "desktop-shell-theme-mode";
    runtimeInputs = [
      pkgs.coreutils
      applyThemeCommand
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: desktop-shell-theme-mode dark|light|toggle" >&2
        exit 64
      fi

      current=dark
      if [ -f "${modePath}" ]; then
        current=$(tr -d '[:space:]' < "${modePath}")
      fi

      case "$current" in
        dark|light|"")
          ;;
        *)
          echo "desktop-shell-theme-mode: invalid current mode in ${modePath}: $current" >&2
          echo "Expected: dark or light" >&2
          exit 65
          ;;
      esac

      case "$1" in
        dark|light)
          mode=$1
          ;;
        toggle)
          if [ "$current" = light ]; then
            mode=dark
          else
            mode=light
          fi
          ;;
        *)
          echo "Usage: desktop-shell-theme-mode dark|light|toggle" >&2
          exit 64
          ;;
      esac

      mkdir -p "$(dirname "${modePath}")"
      printf '%s\n' "$mode" > "${modePath}"

      if [ -f "${lastWallpaperPath}" ]; then
        wallpaper=$(head -n 1 "${lastWallpaperPath}")
        if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
          desktop-shell-apply-theme "$wallpaper"
        fi
      fi
    '';
  };
in
{
  options.local.gui.desktopShell.theme = {
    templates = lib.mkOption {
      description = ''
        Standalone matugen template inventory for the lightweight desktop shell.

        This is exposed in Nix-friendly camelCase. The standalone runner turns
        it into matugen's snake_case TOML format. Consumer submodules should
        register their own templates here.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            inputPath = lib.mkOption {
              type = lib.types.path;
              description = "Local matugen template path.";
            };

            outputPath = lib.mkOption {
              type = lib.types.str;
              description = "Future neutral output path for the generated theme.";
            };

            preHook = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional matugen pre hook command.";
            };

            postHook = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional matugen post hook command.";
            };
          };
        }
      );
    };

    customColors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Custom colors passed to matugen as config.custom_colors.

        These colors are available to templates under the colors namespace and
        are harmonized with the wallpaper source color by matugen.
      '';
    };

    matugenConfig = lib.mkOption {
      readOnly = true;
      type = lib.types.path;
      description = "Build-time generated matugen TOML config for desktop-shell theme templates.";
    };

    applyThemeCommand = lib.mkOption {
      readOnly = true;
      type = lib.types.package;
      description = "Manual desktop-shell matugen runner package.";
    };

    themeModeCommand = lib.mkOption {
      readOnly = true;
      type = lib.types.package;
      description = "Runtime desktop-shell theme mode command package.";
    };
  };

  config = {
    local.gui.desktopShell.theme = {
      inherit matugenConfig applyThemeCommand themeModeCommand;

      customColors = {
        red = "#ff0000";
        green = "#00ff00";
        blue = "#0000ff";
        yellow = "#ffff00";
        magenta = "#ff00ff";
        cyan = "#00ffff";
      };

      templates = { };
    };

    home.packages = [
      applyThemeCommand
      themeModeCommand
    ];
  };
}
