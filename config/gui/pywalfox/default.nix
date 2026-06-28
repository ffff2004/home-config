{ config, lib, pkgs, ... }:
let
  cacheHome = config.xdg.cacheHome;
  colorsPath = "${cacheHome}/wal/colors-matugen.json";
  pywalfoxColorsPath = "${cacheHome}/wal/colors.json";
  cp = lib.getExe' pkgs.coreutils "cp";
  pywalfox = lib.getExe pkgs.pywalfox-native;
in
{
  home.packages = [ pkgs.pywalfox-native ];

  local.gui.desktopShell.theme.templates.pywalfox = {
    # Source: config/gui/noctalia-shell/user-templates/pywalfox.json
    inputPath = ./colors.json;
    outputPath = colorsPath;
    postHook = "${cp} ${colorsPath} ${pywalfoxColorsPath} && ${pywalfox} {{mode}} && ${pywalfox} update";
  };
}
