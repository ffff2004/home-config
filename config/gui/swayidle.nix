{
  config,
  lib,
  pkgs,
  pkgsFrom,
  ...
}:
{
  services.swayidle =
    let
      qs = config.lib.genericLinux.wrapIfEnabled pkgsFrom.noctalia.default "qs";
      lockScreen = "swaylock";
      powerOffMonitors = config.lib.genericLinux.getCmd config.programs.niri.package "niri msg action power-off-monitors";
      sleep = config.lib.genericLinux.getCmd pkgs.systemd "systemctl suspend";
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 900;
          command = powerOffMonitors;
        }
        {
          timeout = 1200;
          command = lockScreen;
        }
        # {
        #   timeout = 2400;
        #   command = sleep;
        # }
      ];
      events = [
        {
          event = "before-sleep";
          command = lockScreen;
        }
      ];
    };
}
