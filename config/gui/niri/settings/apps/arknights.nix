{
  programs.niri.settings = {
    window-rules = [
      {
        matches = [
          { app-id = "maa.exe"; }
          { app-id = "waydroid.com.hypergryph.arknights"; }
        ];
        open-on-workspace = "arknights";
      }
    ];
    workspaces.arknights = { };
  };
}
