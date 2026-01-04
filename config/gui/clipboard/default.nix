{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = pkgs.stdenvNoCC.shell;
in
{
  systemd.user.services.clipboard-bridge-wl-to-x11 = {
    Service = {
      Type = "exec";
      ExecStart = "wl-paste --watch ${shell} ${./bridge-wl-to-x11.sh}";
    };
    Unit = {
      Description = "Bridge Wayland clipboard to X11";
      Documentation = "https://github.com/bugaevc/wl-clipboard";
      After = config.wayland.systemd.target;
    };
    Install = {
      WantedBy = [ config.wayland.systemd.target ];
    };
  };
  systemd.user.services.clipboard-bridge-x11-to-wl = {
    Service = {
      Type = "exec";
      ExecStart = "${shell} ${./bridge-x11-to-wl.sh}";
    };
    Unit = {
      Description = "Bridge X11 clipboard to Wayland";
      Documentation = "https://github.com/bugaevc/wl-clipboard";
      After = config.wayland.systemd.target;
    };
    Install = {
      WantedBy = [ config.wayland.systemd.target ];
    };
  };
}
