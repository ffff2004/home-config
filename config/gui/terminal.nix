{ config, pkgs, ... }:
let
  opacity = 0.83;
  padding = 8;
  font = {
    family = builtins.head config.fonts.fontconfig.defaultFonts.monospace;
    size = 11;
  };
in
{
  xdg.terminal-exec = {
    enable = true;
    settings = {
      niri = [ "Alacritty.desktop" ];
    };
  };
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty-graphics;
    settings = {
      general.import = [ "themes/noctalia.toml" ];
      font = {
        normal = {
          family = font.family;
        };
        size = font.size;
      };
      window = {
        padding = {
          x = padding;
          y = padding;
        };
        opacity = opacity;
      };
    };
  };
  programs.kitty = {
    enable = false;
    font = {
      name = font.family;
      size = font.size;
    };
    settings = {
      window_padding_width = padding / 2.0;
      background_opacity = opacity;
      include = "~/.config/kitty/themes/noctalia.conf";
    };
  };
  programs.foot = {
    enable = false;
    settings = {
      main = {
        font = "${font.family}:size=${toString font.size}";
        include = "~/.config/foot/themes/noctalia";
        pad = "${toString padding}x${toString padding}";
      };
      colors.alpha = opacity;
    };
  };
}
