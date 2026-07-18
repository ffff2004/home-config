{
  lib,
  localLib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  enable = true;
in
lib.mkIf enable {
  xdg.configFile."uv/uv.toml".source = localLib.mkSymlinkToSource ./uv.toml;
  home = {
    packages = [
      pkgs.uv
      pkgs.python3
      pkgsFrom.self.nix-py
    ];
  };
}
