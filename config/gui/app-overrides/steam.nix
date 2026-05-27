{ pkgs, ... }:
let
  wrapper = pkgs.writeShellScriptBin "steam-fym" ''
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
    Exec=${wrapper}/bin/steam-fym %U
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
    Exec=${wrapper}/bin/steam-fym steam://store

    [Desktop Action Community]
    Name=Community
    Exec=${wrapper}/bin/steam-fym steam://url/CommunityHome/

    [Desktop Action Library]
    Name=Library
    Exec=${wrapper}/bin/steam-fym steam://open/games

    [Desktop Action Servers]
    Name=Servers
    Exec=${wrapper}/bin/steam-fym steam://open/servers

    [Desktop Action Screenshots]
    Name=Screenshots
    Exec=${wrapper}/bin/steam-fym steam://open/screenshots

    [Desktop Action News]
    Name=News
    Exec=${wrapper}/bin/steam-fym steam://openurl/https://store.steampowered.com/news

    [Desktop Action Settings]
    Name=Settings
    Exec=${wrapper}/bin/steam-fym steam://open/settings

    [Desktop Action BigPicture]
    Name=Big Picture
    Exec=${wrapper}/bin/steam-fym steam://open/bigpicture

    [Desktop Action Friends]
    Name=Friends
    Exec=${wrapper}/bin/steam-fym steam://open/friends
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
