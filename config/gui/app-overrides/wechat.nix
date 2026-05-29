{ pkgs, lib, ... }:
let
  wrapper = pkgs.writeShellScriptBin "wechat" ''
    exec env QT_IM_MODULE=fcitx /opt/wechat/wechat "$@"
  '';
in
{
  home.packages = [ wrapper ];

  xdg.dataFile."applications/wechat.desktop".text = ''
    [Desktop Entry]
    Name=wechat
    Name[zh_CN]=微信
    Exec=${lib.getExe wrapper} %U
    StartupNotify=true
    Terminal=false
    Icon=/usr/share/icons/hicolor/256x256/apps/wechat.png
    Type=Application
    Categories=Utility;
    Comment=Wechat Desktop
    Comment[zh_CN]=微信桌面版
  '';
}
