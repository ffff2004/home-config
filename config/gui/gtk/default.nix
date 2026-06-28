{ config, ... }:
let
  configHome = config.xdg.configHome;
in
{
  gtk = {
    enable = true;
    gtk3.extraCss = ''
      @import url("file://${configHome}/gtk-3.0/matugen.css");
    '';
    gtk4.extraCss = ''
      @import url("file://${configHome}/gtk-4.0/matugen.css");
    '';
  };

  local.gui.desktopShell.theme.templates = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk3.css
    gtk3 = {
      inputPath = ./gtk3.css;
      outputPath = "${configHome}/gtk-3.0/matugen.css";
    };

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk4.css
    gtk4 = {
      inputPath = ./gtk4.css;
      outputPath = "${configHome}/gtk-4.0/matugen.css";
    };
  };
}
