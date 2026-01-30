{
  config,
  pkgs,
  ...
}:
{
  services.swayidle =
    let
      lockScreen = config.lib.genericLinux.getCmd pkgs.swaylock "swaylock -f";
      powerOffMonitors = config.lib.genericLinux.getCmd config.programs.niri.package "niri msg action power-off-monitors";
      freezeShell = config.lib.genericLinux.getCmd pkgs.systemd "systemctl --user freeze noctalia-shell.service";
      unfreezeShell = config.lib.genericLinux.getCmd pkgs.systemd "systemctl --user thaw noctalia-shell.service";
      sleep = config.lib.genericLinux.getCmd pkgs.systemd "systemctl suspend";
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 900;
          command = freezeShell;
          resumeCommand = unfreezeShell;
        }
        {
          timeout = 900;
          command = powerOffMonitors;
        }
        {
          timeout = 1200;
          command = lockScreen;
        }
        {
          timeout = 28800;
          command = sleep;
        }
      ];
      events = {
        before-sleep = lockScreen;
      };
    };
}
