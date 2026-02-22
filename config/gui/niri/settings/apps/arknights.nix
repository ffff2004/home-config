{
  programs.niri.settings =
    let
      workspace = "arknights";
    in
    {
      window-rules = [
        {
          matches = [
            { app-id = "^maa.exe$"; }
            { app-id = "^waydroid.com.hypergryph.arknights$"; }
          ];
          open-on-workspace = workspace;
        }
        {
          matches = [
            {
              title = "^明日方舟$";
              app-id = "^steam_app|arknights.exe";
            }
            {
              title = "^Form$";
              app-id = "^platformprocess.exe$";
              # is-floating = true;
            }
          ];
          open-floating = false;
          open-fullscreen = true;
          open-on-workspace = workspace;
        }

        {
          matches = [
            {
              title = "^Form$";
              app-id = "^steam_app";
              # is-floating = true;
            }
            {
              title = "^Endfield$";
              app-id = "^steam_app|^Endfield.exe$";
            }
          ];
          open-floating = false;
          open-on-workspace = workspace;
        }

        {
          matches = [
            {
              title = "^EFTool$|^其他选项$";
              app-id = "^steam_app|^eftool.exe$";
              # is-floating = true;
            }
          ];
          open-floating = false;
          open-on-workspace = workspace;
        }
        {
          matches = [
            {
              title = "^$";
              app-id = "^steam_app";
              # is-floating = true;
            }
            {
              title = "^$";
              app-id = "^explorer.exe$";
              # is-floating = true;
            }
            {
              title = "^鹰角启动器$";
              # app-id = "^steam_app";
              # is-floating = true;
            }
          ];
          open-floating = false;
          open-on-workspace = workspace;
        }
      ];
      workspaces.${workspace} = { };
    };
}
