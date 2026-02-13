{
  config,
  pkgs,
  lib,
  ...
}:
let
  pkg = config.lib.umu.buildProtonApp {
    bin = "X:/Downloads/EFTool.exe";
    name = "endfield";
    desktopName = "Endfield";
    description = "明日方舟：终末地";
    icon = pkgs.fetchurl {
      url = "https://bbs.hycdn.cn/asset/endfield.png";
      hash = "sha256-6lRgKGADro9Qq8U/mcp4xoIZiQiWsb9uBYwHRihoZZY=";
    };
    iconSize = 500;
    gameId = "yj";
    umu-launcher-wrapper = config.umu.eval.packages.dw-wl;
    preCmd = "${lib.getExe pkgs.wlr-randr} --output eDP-1 --scale 1";
    wrapperCmd = "env PROTON_DXVK_GPLASYNC=1 WINE_CANONICAL_HOLE=skip_volatile_check";
    postCmd = "${lib.getExe pkgs.wlr-randr} --output eDP-1 --scale 1.5";
  };
in
{
  home.packages = [ pkg ];
}
