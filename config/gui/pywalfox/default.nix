{ config, lib, pkgs, ... }:
let
  cacheHome = config.xdg.cacheHome;
  pywalfoxColorsPath = "${cacheHome}/wal/colors.json";
  pywalfox = lib.getExe pkgs.pywalfox-native;
in
{
  home.packages = [ pkgs.pywalfox-native ];

  local.gui.theme.templates.pywalfox = {
    # Source: config/gui/noctalia-shell/user-templates/pywalfox.json
    inputPath = ./colors.json;
    outputPath = pywalfoxColorsPath;
    postHook = "${pywalfox} {{mode}} && ${pywalfox} update";
  };
}
