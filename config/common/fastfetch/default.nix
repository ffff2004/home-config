{ pkgs, localLib, ... }:
let
  pkg = pkgs.fastfetch;
in
{
  home.packages = [
    pkg
  ];
  home.file.".config/fastfetch/config.jsonc".source = localLib.mkSymlinkToSource ./config.jsonc;
}
