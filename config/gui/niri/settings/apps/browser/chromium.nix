{
  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^chromium-browser$"; } ];
      open-on-workspace = "browser";
    }
  ];
}
