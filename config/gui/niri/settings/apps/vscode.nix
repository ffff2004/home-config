{ config, ... }:
{
  programs.niri.settings.window-rules = [
    {
      matches = [
        { app-id = "^code$"; }
      ];
      default-column-width.proportion = 2. / 3;
    }
  ];
  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+C" = {
      action = spawn "code";
      repeat = false;
      hotkey-overlay.title = "Run an Application: Visual Studio Code";
    };
  };
}
