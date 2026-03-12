{ pkgs, localLib, ... }:
let
  pkg = pkgs.fastfetch;
in
{
  home.packages = [
    pkg
  ];
  xdg.configFile."fastfetch/config.jsonc".source = localLib.mkSymlinkToSource ./config.jsonc;
}
