{
  config,
  pkgs,
  ...
}:
{
  services.swayidle =
    let
      lockSession = config.local.gui.lockSession.command;
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
      ]
      ++ [
        {
          timeout = 1200;
          command = lockSession;
        }
        {
          timeout = 28800;
          command = sleep;
        }
      ];
      events = {
        before-sleep = lockSession;
      };
    };
}
