{
  inputs,
  config,
  pkgs,
  lib,
  localLib,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
    #./niri.nix
    ./user-templates
  ];
  programs.noctalia-shell = {
    enable = true;
    # package = config.lib.genericLinux.wrapIfEnabled pkgsFrom.noctalia.default "qs -c noctalia-shell";
    settings = localLib.mkSymlinkToSource ./config/settings.json;
  };
}
