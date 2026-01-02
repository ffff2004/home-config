{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.umu;
  wrapper = pkgs.callPackage ./umu-launcher-wrapper.nix {
    umu-launcher = cfg.package;
    inherit (cfg) protonPath;
  };
  wrapperWithWayland = pkgs.callPackage ./umu-launcher-wrapper.nix {
    umu-launcher = cfg.package;
    inherit (cfg) protonPath;
    enableWayland = true;
  };
in
{
  options.umu =
    let
      inherit (lib) mkOption types;
    in
    {
      package = mkOption {
        type = types.package;
        default = config.lib.genericLinux.wrapIfEnabled pkgs.umu-launcher "umu-run";
      };
      wrapper = mkOption {
        type = types.package;
        readOnly = true;
      };
      wrapperWithWayland = mkOption {
        type = types.package;
        readOnly = true;
      };
      protonPath = mkOption {
        type = types.either types.str types.path;
      };
    };
  config = {
    umu = {
      protonPath = "$HOME/.steam/steam/compatibilitytools.d/GE-Proton10-25";
      inherit wrapper wrapperWithWayland;
    };
    home.packages = [ wrapper ];
  };
  imports = [ ./apps ];
}
