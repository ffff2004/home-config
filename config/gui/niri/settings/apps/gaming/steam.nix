{
  programs.niri.settings.window-rules = [
    {
      matches = [
        {
          app-id = "^steam$";
          title = "^notificationtoasts_\\d+_desktop$";
        }
      ];
      default-floating-position = {
        x = 10;
        y = 10;
        relative-to = "bottom-right";
      };
    }
    {
      matches = [
        { app-id = "^steam$"; }
      ];
      excludes = [
        { title = "^notificationtoasts_\\d+_desktop$"; }
        { title = "^登录 Steam$"; }
        { title = "^关机$"; }
      ];
      open-on-workspace = "gaming";
      open-focused = true;
    }
  ];
}
