{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.umu;
in
{
  options.umu = {
    package = mkOption {
      type = types.package;
      default = config.lib.genericLinux.wrapIfEnabled pkgs.umu-launcher "umu-run";
    };
    wrappers = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              exe = mkOption {
                type = types.str;
                default = "umu-run-${name}";
              };
              protonPath = mkOption {
                type = types.either types.path types.str;
              };
              enableWayland = mkOption {
                type = types.bool;
                default = false;
              };
            };
          }
        )
      );
      default = { };
      description = "Enable wrappers for umu-launcher with specific features.";
    };
    eval.packages = mkOption {
      type = types.lazyAttrsOf types.package;
      readOnly = true;
      default = lib.mapAttrs (
        name: subcfg:
        pkgs.callPackage ./umu-launcher-wrapper.nix (
          {
            umu-launcher = config.umu.package;
          }
          // subcfg
        )
      ) config.umu.wrappers;
    };
  };
  config = {
    umu = {
      wrappers =
        let
          compatibilityToolsPath = "$HOME/.local/share/Steam/compatibilitytools.d";
          gePath = "${compatibilityToolsPath}/Proton-GE Latest";
          dwPath = "${compatibilityToolsPath}/dwproton";
        in
        {
          ge.protonPath = gePath;
          ge-wl = {
            protonPath = gePath;
            enableWayland = true;
          };
          dw.protonPath = dwPath;
        };
    };
    home.packages = builtins.attrValues cfg.eval.packages;
  };
  imports = [ ./apps ];
}
