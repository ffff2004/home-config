{
  programs.niri.settings = {
    window-rules = [
      {
        matches = [
          { app-id = "^maa.exe$"; }
          { app-id = "^waydroid.com.hypergryph.arknights$"; }
          { app-id = "^elysia$"; }
          {
            title = "^Endfield$";
            app-id = "^steam_app_default$";
          }
        ];
        open-on-workspace = "arknights";
      }
      {
        matches = [
          {
            title = "^Form$";
            app-id = "^steam_app_default$";
            is-floating = true;
          }
        ];
        open-floating = false;
      }
      {
        matches = [
          {
            title = "^Form$";
            app-id = "^steam_app_default$";
            is-floating = false;
          }
        ];
        open-floating = true;
      }
      {
        matches = [
          {
            title = "^$";
            app-id = "^steam_app_default$";
            is-floating = true;
          }
          {
            title = "^鹰角启动器$";
            app-id = "^steam_app_default$";
            is-floating = true;
          }
        ];
        open-floating = false;
      }
    ];
    workspaces.arknights = { };
  };
}
