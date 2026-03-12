{
  config,
  pkgs,
  localLib,
  lib,
  ...
}:
let
  cfg = config.i18n.inputMethod;
  enable = cfg.enable && cfg.type == "fcitx5";
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        kdePackages.fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-pinyin-moegirl
        fcitx5-pinyin-minecraft
        fcitx5-pinyin-zhwiki
      ];
    };
  };
  xdg.configFile = lib.mkIf enable (
    lib.genAttrs' (localLib.lsFileRecursively ./config) (
      file:
      lib.nameValuePair "fcitx5/${lib.removePrefix ((toString ./config) + "/") (toString file)}" {
        source = localLib.mkSymlinkToSource file;
      }
    )
  );
  # home.sessionVariables = lib.mkIf enable { QT_IM_MODULES = "wayland;fcitx"; };
}
