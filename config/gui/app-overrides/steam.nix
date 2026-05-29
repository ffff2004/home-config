{ pkgs, lib, ... }:
let
  wrapper = pkgs.writeShellScriptBin "steam" ''
    exec /usr/bin/steam \
      -noverifyfiles \
      -nobootstrapupdate \
      -skipinitialbootstrap \
      -norepairfiles \
      -overridepackageurl \
      -system-composer \
      "$@"
  '';
in
{
  home.packages = [ wrapper ];

  xdg.dataFile."applications/steam.desktop".text = ''
    [Desktop Entry]
    Name=Steam
    Comment=Application for managing and playing games on Steam
    Comment[zh_CN]=管理和进行 Steam 游戏的应用程序
    Exec=${lib.getExe wrapper} %U
    Icon=steam
    Terminal=false
    Type=Application
    Categories=Network;FileTransfer;Game;
    MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
    Actions=Store;Community;Library;Servers;Screenshots;News;Settings;BigPicture;Friends;
    PrefersNonDefaultGPU=true
    X-KDE-RunOnDiscreteGpu=true

    [Desktop Action Store]
    Name=Store
    Exec=${lib.getExe wrapper} steam://store

    [Desktop Action Community]
    Name=Community
    Exec=${lib.getExe wrapper} steam://url/CommunityHome/

    [Desktop Action Library]
    Name=Library
    Exec=${lib.getExe wrapper} steam://open/games

    [Desktop Action Servers]
    Name=Servers
    Exec=${lib.getExe wrapper} steam://open/servers

    [Desktop Action Screenshots]
    Name=Screenshots
    Exec=${lib.getExe wrapper} steam://open/screenshots

    [Desktop Action News]
    Name=News
    Exec=${lib.getExe wrapper} steam://openurl/https://store.steampowered.com/news

    [Desktop Action Settings]
    Name=Settings
    Exec=${lib.getExe wrapper} steam://open/settings

    [Desktop Action BigPicture]
    Name=Big Picture
    Exec=${lib.getExe wrapper} steam://open/bigpicture

    [Desktop Action Friends]
    Name=Friends
    Exec=${lib.getExe wrapper} steam://open/friends
  '';

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "x-scheme-handler/steam" = "steam.desktop";
      "x-scheme-handler/steamlink" = "steam.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/steam" = "steam.desktop";
      "x-scheme-handler/steamlink" = "steam.desktop";
    };
  };
}
