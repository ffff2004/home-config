{
  programs.niri.settings.window-rules = [
    {
      matches = [
        { app-id = "polkit-gnome-authentication-agent-1"; }
      ];
      geometry-corner-radius =
        let
          r = 15.0;
        in
        {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
      clip-to-geometry = true;
    }
  ];
}
