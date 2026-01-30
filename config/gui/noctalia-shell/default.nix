{
  inputs,
  config,
  pkgs,
  pkgsFrom,
  lib,
  localLib,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./niri.nix
    ./user-templates
  ];
  programs.noctalia-shell = {
    enable = true;
    # package = config.lib.genericLinux.wrapIfEnabled pkgsFrom.noctalia.default "qs -c noctalia-shell";
    systemd.enable = true;
    settings = localLib.mkSymlinkToSource ./config/settings.json;
  };
  home.packages = lib.mkIf config.programs.noctalia-shell.enable [
    pkgs.app2unit
    pkgsFrom.matugen.default
  ];
}
