{
  pkgs,
  localLib,
  ...
}:
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
  xdg.configFile = localLib.mkSymlinkToSourceRecursively "fcitx5" ./config;

  # home.sessionVariables = lib.mkIf enable { QT_IM_MODULES = "wayland;fcitx"; };
}
