{
  programs.niri.settings = {
    window-rules = [
      {
        matches = [
          { title = "^Minecraft"; }
          { app-id = "^org.jackhuang.hmcl.Launcher$"; }
          { app-id = "^org.prismlauncher.PrismLauncher$"; }
        ];
        open-on-workspace = "mc";
      }
      {
        matches = [
          { app-id = "^org.prismlauncher.PrismLauncher$"; }
        ];
        open-floating = false;
      }
    ];
    workspaces.mc = { };
  };
}
