umu-launcher-wrapper:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  maaPath = "$HOME/Games/maa";
  pkg = pkgs.callPackage ./maa-proton.nix {
    inherit maaPath;
    umu-launcher-wrapper = config.umu.wrapperWithWayland;
  };
in
{
  home.packages = [ pkg ];
}
