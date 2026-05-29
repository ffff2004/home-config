{
  config,
  lib,
  localLib,
  pkgs,
  ...
}:
let
  enable = true;
in
lib.mkIf enable (
  let
    pnpmHome = "${config.xdg.dataHome}/pnpm";
  in
  {
    home = {
      packages = [
        pkgs.nodejs-slim
        pkgs.pnpm
      ];
      file.".npmrc".source = localLib.mkSymlinkToSource ./.npmrc;
      sessionVariables = {
        PNPM_HOME = pnpmHome;
      };
      sessionSearchVariables.PATH = [
        "${pnpmHome}/bin"
      ];
    };
  }
)
