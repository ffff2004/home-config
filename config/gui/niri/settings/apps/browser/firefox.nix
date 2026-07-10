{ config, ... }:
{
  programs.niri.settings.window-rules =
    let
      app-id = "^firefox$";
    in
    [
      {
        matches = [ { inherit app-id; } ];
        open-on-workspace = "browser";
      }

      # {
      #   matches = [
      #     {
      #       inherit app-id;
      #       title = "^Picture-in-Picture|画中画$";
      #     }
      #   ];
      #   open-floating = true;
      # }

      {
        matches = [
          { inherit app-id; }
        ];
        excludes = [
          {
            # exclude master password / PiP
            is-floating = true;
          }
          {
            title = "文件";
          }
        ];
        default-column-width.proportion = .75;
      }

      {
        matches = [
          {
            inherit app-id;
          }
        ];
        excludes = [
          {
            title = "密码";
          }
        ];
        open-floating = false;
      }
    ];

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+B" = {
      action = spawn "firefox";
      repeat = false;
      hotkey-overlay.title = "Run an Application: Firefox";
    };
  };
}
