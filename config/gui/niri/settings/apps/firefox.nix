{ config, ... }:
{
  programs.niri.settings.window-rules =
    let
      app-id = "^firefox$";
    in
    [
      {
        matches = [
          {
            inherit app-id;
            title = "^Picture-in-Picture|画中画$";
          }
        ];
        open-floating = true;
      }

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
            title = "^文件上传 - ";
          }
        ];
        open-maximized = true;
      }

      {
        matches = [
          {
            inherit app-id;
            title = "^文件上传 - ";
          }
        ];
        open-floating = false;
      }
    ];

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+B" = {
      action = spawn "firefox";
      hotkey-overlay.title = "Run an Application: Firefox";
    };
  };
}
