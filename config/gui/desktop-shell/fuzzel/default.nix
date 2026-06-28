{ config, pkgs, ... }:
let
  configHome = config.xdg.configHome;
in
{
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    include=${configHome}/fuzzel/themes/matugen.ini
  '';

  local.gui.desktopShell.theme.templates.fuzzel = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/fuzzel.conf
    inputPath = ./matugen.ini;
    outputPath = "${configHome}/fuzzel/themes/matugen.ini";
  };
}
