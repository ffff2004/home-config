{
  config,
  lib,
  localLib,
  ...
}:
{
  programs.npm.enable = true;
}
// lib.mkIf config.programs.npm.enable {
  home.file.".npmrc".source = localLib.mkSymlinkToSource ./npmrc;
}
