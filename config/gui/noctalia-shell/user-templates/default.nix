{
  pkgs,
  lib,
  config,
  localLib,
  ...
}:
{
  programs.noctalia-shell.user-templates = {
    config = { };
    templates = {
      alacritty = {
        input_path = localLib.mkSymlinkToSource ./alacritty.toml;
        output_path = "~/.config/alacritty/themes/noctalia.toml";
      };
    };
  };
  home.packages = lib.mkIf config.programs.noctalia-shell.enable [ pkgs.pywalfox-native ];
}
