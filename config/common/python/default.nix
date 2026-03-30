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
  xdg.configFile."uv/uv.toml".source = localLib.mkSymlinkToSource ./uv.toml;
  home = {
    packages = [
      pkgs.uv
      (pkgs.writeShellScriptBin "nix-py" (builtins.readFile ./nix-py.sh))
    ];
  };
}
