{ pkgs, ... }:
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
      font.size = 11;
      window = {
        padding = {
          x = 10;
          y = 8;
        };
        opacity = .83;
      };
    };
  };
  programs.kitty = {
    enable = false;
    font = {
      name = "monospace";
      size = 11;
    };
    settings = {
      window_padding_width = 5;
      background_opacity = .83;
      include = "~/.config/kitty/themes/noctalia.conf";
    };
  };
  programs.foot = {
    enable = false;
    settings = {
      main = {
        font = "monospace:size=11";
        include = "~/.config/foot/themes/noctalia";
        pad = "10x10";
      };
      colors.alpha = .83;
    };
  };
}
