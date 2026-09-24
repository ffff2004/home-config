{
  programs.niri.settings.outputs =
    let
      "redmi-24-2560-1440-180" = {
        mode = {
          refresh = 119.998;
          width = 2560;
          height = 1440;
        };
        position = {
          x = 1707;
          y = -125;
        };
        variable-refresh-rate = true;
      };
    in
    {
      # built-in
      eDP-1 = {
        position = {
          x = 0;
          y = 0;
        };
        variable-refresh-rate = true;
      };
      DP-1 = redmi-24-2560-1440-180;
    };
}
