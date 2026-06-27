{ lib, ... }:
let
  templateRoot = ./templates;

  mkTemplate =
    fileName: outputPath:
    {
      inherit outputPath;
      inputPath = templateRoot + "/${fileName}";
    };
in
{
  options.local.gui.desktopShell.theme.templates = lib.mkOption {
    readOnly = true;
    description = ''
      Standalone matugen template inventory for the lightweight desktop shell.

      This is metadata only for now. A later migration step will add the
      matugen runner that writes these templates to their output paths.
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

  config.local.gui.desktopShell.theme.templates = {
    # Source: config/gui/noctalia-shell/user-templates/alacritty.toml
    alacritty = mkTemplate
      "alacritty.toml"
      "~/.config/alacritty/themes/matugen.toml";

    # Source: config/gui/noctalia-shell/user-templates/swaylock.conf
    swaylock = mkTemplate
      "swaylock.conf"
      "~/.config/swaylock/themes/matugen.conf";

    # Source: config/gui/noctalia-shell/user-templates/pywalfox.json
    pywalfox = mkTemplate
      "pywalfox.json"
      "~/.cache/wal/colors-matugen.json";

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk3.css
    gtk3 = mkTemplate
      "gtk3.css"
      "~/.config/gtk-3.0/matugen.css";

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk4.css
    gtk4 = mkTemplate
      "gtk4.css"
      "~/.config/gtk-4.0/matugen.css";

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
    qt5ct = mkTemplate
      "qtct.conf"
      "~/.config/qt5ct/colors/matugen.conf";

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
    qt6ct = mkTemplate
      "qtct.conf"
      "~/.config/qt6ct/colors/matugen.conf";

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/fuzzel.conf
    fuzzel = mkTemplate
      "fuzzel.ini"
      "~/.config/fuzzel/themes/matugen.ini";
  };
}
