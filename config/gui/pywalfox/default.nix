{
  config,
  lib,
  localLib,
  pkgs,
  ...
}:
let
  cacheHome = config.xdg.cacheHome;
  pywalfoxColorsPath = "${cacheHome}/wal/colors.json";
  pywalfox = lib.getExe pkgs.pywalfox-native;
in
{
  home.packages = [ pkgs.pywalfox-native ];

  home.file.".mozilla/native-messaging-hosts/pywalfox.json".source =
    localLib.mkSymlinkToSource ./pywalfox.json;

  local.gui.theme.templates.pywalfox = {
    # Source: config/gui/noctalia-shell/user-templates/pywalfox.json
    inputPath = ./colors.json;
    outputPath = pywalfoxColorsPath;
    postHook = "${pywalfox} {{mode}} && ${pywalfox} update";
  };
}
