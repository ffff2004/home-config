{
  config,
  pkgs,
  ...
}:
{
  systemd.user.services.polkit-agent =
    let
      inherit (config.wayland.systemd) target;
    in
    {
      Service = {
        Type = "exec";
        ExecStart =
          if config.targets.genericLinux.enable then
            "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
          else
            "${pkgs.polkit-gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = "3";
      };
      Unit = {
        Description = "GNOME PolicyKit Authentication Agent";
        After = target;
      };
      Install = {
        WantedBy = [ target ];
      };
    };
}
