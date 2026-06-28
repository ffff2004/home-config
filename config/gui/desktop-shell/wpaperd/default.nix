{
  config,
  lib,
  pkgs,
  ...
}:
let
  applyThemeCommand = lib.getExe config.local.gui.desktopShell.theme.applyThemeCommand;
  themeHook = pkgs.writeShellApplication {
    name = "desktop-shell-wpaperd-theme-hook";
    text = ''
      if [ "$#" -lt 2 ]; then
        echo "Usage: desktop-shell-wpaperd-theme-hook DISPLAY WALLPAPER" >&2
        exit 64
      fi

      wallpaper=$2
      if [ ! -f "$wallpaper" ]; then
        echo "desktop-shell-wpaperd-theme-hook: wallpaper not found: $wallpaper" >&2
        exit 0
      fi

      exec ${applyThemeCommand} "$wallpaper"
    '';
  };
in
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        duration = "1h";
        exec = lib.getExe themeHook;
        mode = "fit-border-color";
        sorting = "random";
        recursive = false;
        "queue-size" = 100;
        "transition-time" = 1000;
      };

      any = {
        path = "/home/fym/Pictures/Wallpapers";
        group = 1;
      };
    };
  };
}
