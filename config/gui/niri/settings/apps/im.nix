{
  programs.niri.settings = {
    window-rules = [
      {
        matches = [
          { app-id = "^wechat$"; }
          { app-id = "^QQ$"; }
          { app-id = "^com.alibabainc.dingtalk$"; }
        ];
        excludes = [ { title = "^com.alibabainc.dingtalk$"; } ];
        open-on-workspace = "im";
      }
      {
        matches = [
          {
            app-id = "^wechat$";
            title = "^Settings$";
          }
          {
            app-id = "^wechat$";
            title = "^设置$";
          }
        ];
        open-floating = false;
      }
      {
        matches = [
          {
            title = "^com.alibabainc.dingtalk$";
            app-id = "^com.alibabainc.dingtalk$";
            # is-floating = true; # Does not match for some reason
          }
        ];
        # open-focused = false;
        default-floating-position = {
          x = 150;
          y = -60;
          relative-to = "bottom-right";
        };
      }
    ];
    workspaces.im = { };
  };
}
