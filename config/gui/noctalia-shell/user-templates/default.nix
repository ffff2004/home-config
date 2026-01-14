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
      pywalfox = {
        input_path = localLib.mkSymlinkToSource ./pywalfox-update.sh;
        output_path = "~/.cache/wal/pywalfox-update.sh";
        post_hook = "sh ~/.cache/wal/pywalfox-update.sh";
      };
    };
  };
  home.packages = lib.mkIf config.programs.noctalia-shell.enable [ pkgs.pywalfox-native ];
}
