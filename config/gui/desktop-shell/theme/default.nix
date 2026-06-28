{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.gui.desktopShell.theme;
  configHome = config.xdg.configHome;
  cacheHome = config.xdg.cacheHome;
  templateRoot = ./templates;

  mkTemplate =
    fileName: outputPath:
    {
      inherit outputPath;
      inputPath = templateRoot + "/${fileName}";
    };

  matugenConfigFormat = pkgs.formats.toml { };

  toMatugenTemplate =
    template:
    lib.filterAttrs (_: value: value != null) {
      input_path = toString template.inputPath;
      output_path = template.outputPath;
      pre_hook = template.preHook;
      post_hook = template.postHook;
    };

  matugenConfig = matugenConfigFormat.generate "desktop-shell-matugen.toml" {
    config = { };
    templates = lib.mapAttrs (_: toMatugenTemplate) cfg.templates;
  };

  applyThemeCommand = pkgs.writeShellApplication {
    name = "desktop-shell-apply-theme";
    runtimeInputs = [ pkgs.matugen ];
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

      exec matugen image "$wallpaper" -c "${matugenConfig}" --source-color-index 0
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
  };

  config = {
    local.gui.desktopShell.theme = {
      inherit matugenConfig applyThemeCommand;

      templates = {
        # Source: config/gui/noctalia-shell/user-templates/alacritty.toml
        alacritty = mkTemplate
          "alacritty.toml"
          "${configHome}/alacritty/themes/matugen.toml";

        # Source: config/gui/noctalia-shell/user-templates/swaylock.conf
        swaylock = mkTemplate
          "swaylock.conf"
          "${configHome}/swaylock/themes/matugen.conf";

        # Source: config/gui/noctalia-shell/user-templates/pywalfox.json
        pywalfox = mkTemplate
          "pywalfox.json"
          "${cacheHome}/wal/colors-matugen.json";

        # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk3.css
        gtk3 = mkTemplate
          "gtk3.css"
          "${configHome}/gtk-3.0/matugen.css";

        # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk4.css
        gtk4 = mkTemplate
          "gtk4.css"
          "${configHome}/gtk-4.0/matugen.css";

        # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
        qt5ct = mkTemplate
          "qtct.conf"
          "${configHome}/qt5ct/colors/matugen.conf";

        # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
        qt6ct = mkTemplate
          "qtct.conf"
          "${configHome}/qt6ct/colors/matugen.conf";

        # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/fuzzel.conf
        fuzzel = mkTemplate
          "fuzzel.ini"
          "${configHome}/fuzzel/themes/matugen.ini";
      };
    };

    home.packages = [ applyThemeCommand ];
  };
}
