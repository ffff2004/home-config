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
      # Use the repo-local package exported from pkgs/default.nix
      pkgsFrom.self.nix-py
    ];
  };
}
