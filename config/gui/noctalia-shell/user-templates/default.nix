{
  pkgs,
  lib,
  config,
  localLib,
  ...
}:
{
  programs.noctalia-shell.user-templates = {
    config = {
      custom_colors = {
        red = "#ff0000";
        green = "#00ff00";
        blue = "#0000ff";
        yellow = "#ffff00";
        magenta = "#ff00ff";
        cyan = "#00ffff";
      };
    };
    templates = {
      alacritty = {
        input_path = localLib.mkSymlinkToSource ./alacritty.toml;
        output_path = "~/.config/alacritty/themes/noctalia.toml";
      };
      swaylock = {
        input_path = localLib.mkSymlinkToSource ./swaylock.conf;
        output_path = "~/.config/swaylock/config";
      };
      pywalfox = {
        input_path = localLib.mkSymlinkToSource ./pywalfox.json;
        output_path = "~/.cache/wal/colors.json";
        post_hook = "pywalfox {{mode}} && pywalfox update";
      };
    };
  };
  home.packages = lib.mkIf config.programs.noctalia-shell.enable [ pkgs.pywalfox-native ];
}
