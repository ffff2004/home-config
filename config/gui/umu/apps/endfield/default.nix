{
  config,
  pkgs,
  ...
}:
let
  pkg = pkgs.callPackage ./endfield.nix {
    endfieldBin = "/mnt/wine/Hypergryph\ Launcher/games/Endfield Game/Endfield.exe";
    umu-launcher-wrapper = config.umu.eval.packages.dw;
  };
in
{
  home.packages = [ pkg ];
}
