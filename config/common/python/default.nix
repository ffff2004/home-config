{
  config,
  lib,
  localLib,
  pkgs,
  ...
}:
{
  programs.uv.enable = true;
  home.packages = [ (pkgs.writeShellScriptBin "nix-py" (builtins.readFile ./nix-py.sh)) ];
}
// lib.mkIf config.programs.uv.enable {
  xdg.configFile."uv/uv.toml".source = localLib.mkSymlinkToSource ./uv.toml;
}
