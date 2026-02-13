{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types recursiveUpdate;
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
              extraEnv = mkOption {
                type = types.attrsOf (
                  types.nullOr (
                    types.oneOf [
                      types.str
                      types.path
                      types.int
                    ]
                  )
                );
                default = { };
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
          igpu_vk_icd_filenames = "/usr/share/vulkan/icd.d/intel_icd.x86_64.json";
        in
        rec {
          dw = {
            protonPath = dwPath;
            extraEnv = {
              PROTON_DXVK_GPLASYNC = 1;
              WINE_CANONICAL_HOLE = "skip_volatile_check";
            };
          };
          dw-wl = recursiveUpdate dw {
            extraEnv = {
              PROTON_ENABLE_WAYLAND = 1;
            };
          };
          dw-wl-igpu = recursiveUpdate dw-wl {
            extraEnv = {
              VK_ICD_FILENAMES = igpu_vk_icd_filenames;
            };
          };
          ge = {
            protonPath = gePath;
          };
          ge-wl = recursiveUpdate ge {
            extraEnv = {
              PROTON_ENABLE_WAYLAND = 1;
            };
          };
          ge-wl-igpu = recursiveUpdate ge-wl {
            extraEnv = {
              VK_ICD_FILENAMES = igpu_vk_icd_filenames;
            };
          };
        };
    };
    home.packages = builtins.attrValues cfg.eval.packages;
  };
  imports = [ ./apps ];
}
