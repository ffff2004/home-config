{
  lib,
  localLib,
  pkgs,
  ...
}:
let
  enable = true;
in
lib.mkIf enable {
  home = {
    packages = [ pkgs.nodejs ];
    file.".npmrc".source = localLib.mkSymlinkToSource ./npmrc;
  };
}
