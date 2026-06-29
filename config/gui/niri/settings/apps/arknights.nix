{
  programs.niri.settings =
    let
      workspace = "arknights";
    in
    {
      window-rules = [
        {
          # 自动 MAA & Waydroid 组
          matches = [
            { title = "^MAA "; }
            { app-id = "^maa.exe$"; }
            { app-id = "^waydroid.com.hypergryph.arknights$"; }
          ];
          open-on-workspace = workspace;
        }

        # 以下为 proton 启动的
        {
          matches = [
            {
              title = "^明日方舟$";
              app-id = "^steam_app|arknights.exe";
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
              app-id = "^steam_app|^platformprocess.exe$";
            }
          ];
          open-floating = false;
          open-on-workspace = workspace;
          open-focused = true;
        }
        {
          matches = [
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
