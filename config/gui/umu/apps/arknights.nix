{
  config,
  pkgs,
  ...
}:
let
  pkg = config.lib.umu.buildProtonApp {
    bin = "W:/wine/Hypergryph Launcher/games/Arknights Game/Arknights.exe";
    name = "arknights";
    desktopName = "Arknights";
    description = "明日方舟";
    icon = pkgs.fetchurl {
      url = "https://bbs.hycdn.cn/asset/rhodes_island.png";
      hash = "sha256-9cTD1clBvKjENVIPf+0DMJw27+pdaJQUtQufj21ehCY=";
    };
    iconSize = 180;
    gameId = "yj";
    umu-launcher-wrapper = config.umu.eval.packages.dw-wl-igpu;
  };
in
{
  home.packages = [ pkg ];
}
