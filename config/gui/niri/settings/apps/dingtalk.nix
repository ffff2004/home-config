{
  programs.niri.settings.window-rules = [
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
}
