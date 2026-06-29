{
  config,
  lib,
  pkgs,
  ...
}:
let
  configHome = config.xdg.configHome;
  terminalExec = lib.getExe config.xdg.terminal-exec.package;
  opacity = 0.83;
  padding = 8;
  font = {
    family = builtins.head config.fonts.fontconfig.defaultFonts.monospace;
    size = 11;
  };
in
{
  local.gui.theme.templates.alacritty = {
    # Migrated from the former Noctalia Alacritty user template.
    inputPath = ./alacritty.toml;
    outputPath = "${configHome}/alacritty/themes/matugen.toml";
  };

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
      general.import = [ "themes/matugen.toml" ];
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
      hints = {
        enabled = [
          {
            command = "xdg-open";
            hyperlinks = true;
            post_processing = true;
            persist = false;
            mouse = {
              mods = "Control";
              enabled = true;
            };
            binding = {
              key = "O";
              mods = "Control|Shift";
            };
            regex = ''(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\u0000-\u001F\u007F-\u009F<>"\\s{-}\\^⟨⟩`\\\\]+'';
          }
          {
            command = {
              program = "alacritty";
              args = [
                "-e"
                "nvim"
              ];
            };
            post_processing = true;
            persist = false;
            mouse = {
              mods = "Control";
              enabled = true;
            };
            binding = {
              key = "E";
              mods = "Control|Shift";
            };
            regex = ''\\/[\\w\\.\\/-]*'';
          }
        ];
      };
    };
  };

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+T" = lib.mkDefault {
      action = spawn terminalExec;
      repeat = false;
      hotkey-overlay.title = "Open a Terminal";
    };

    "XF86Calculator" = {
      action = lib.mkDefault { spawn = [ terminalExec "python" ]; };
      repeat = false;
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
    };
  };
  programs.foot = {
    enable = false;
    settings = {
      main = {
        font = "${font.family}:size=${toString font.size}";
        pad = "${toString padding}x${toString padding}";
      };
      colors.alpha = opacity;
    };
  };
}
