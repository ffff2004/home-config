{
  programs.niri.settings.window-rules = [
    {
      draw-border-with-background = false;
    }

    {
      # proton
      matches = [
        {
          title = "^$";
          app-id = "^explorer.exe$|^steam_app";
          # is-floating = true;
        }
      ];
      open-floating = false;
    }
  ];
}
