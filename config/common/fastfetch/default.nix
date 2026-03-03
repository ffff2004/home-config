{ pkgs, lib, ... }:
let
  pkg = pkgs.fastfetch;
in
{
  home.packages = [
    pkg
  ];
  home.file.".config/fastfetch/config.jsonc".text = lib.replaceString "\"logo\": {" ''
    "logo": {
      "type": "small",'' (builtins.readFile "${pkg}/share/fastfetch/presets/examples/7.jsonc");
}
