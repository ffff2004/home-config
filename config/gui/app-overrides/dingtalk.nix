{ pkgs, lib, ... }:
let
  wrapper = pkgs.writeShellScriptBin "dingtalk" ''
    exec env QT_IM_MODULE=fcitx /usr/bin/dingtalk "$@"
  '';
in
{
  home.packages = [ wrapper ];

  xdg.dataFile."applications/com.alibabainc.dingtalk.desktop".text = ''
    [Desktop Entry]
    Categories=Chat;Network;
    Comment=DingTalk Desktop
    Exec=${lib.getExe wrapper} %u
    GenericName=dingtalk
    Icon=dingtalk
    Keywords=dingtalk;
    MimeType=x-scheme-handler/dingtalk;
    Name=DingTalk
    Name[zh_CN]=钉钉
    Type=Application
    X-Deepin-Vendor=user-custom
  '';

  xdg.mimeApps = {
    enable = true;
    associations.added."x-scheme-handler/dingtalk" = "com.alibabainc.dingtalk.desktop";
    defaultApplications."x-scheme-handler/dingtalk" = "com.alibabainc.dingtalk.desktop";
  };
}
