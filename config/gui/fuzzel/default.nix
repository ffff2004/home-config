{ config, ... }:
let
  configHome = config.xdg.configHome;
in
{
  programs.fuzzel = {
    enable = true;
    settings.main.include = "${configHome}/fuzzel/themes/matugen.ini";
  };

  local.gui.theme.templates.fuzzel = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/fuzzel.conf
    inputPath = ./matugen.ini;
    outputPath = "${configHome}/fuzzel/themes/matugen.ini";
  };
}
