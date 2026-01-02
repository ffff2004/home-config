{
  config,
  ...
}:
{
  systemd.user.services.clipboard-bridge = {
    Service = {
      Type = "exec";
      ExecStart = "/usr/bin/wl-paste --type text --watch /usr/bin/xclip -selection clipboard";
    };
    Unit = {
      Description = "Bridge Wayland clipboard to X11 clipboard";
      Documentation = "https://github.com/bugaevc/wl-clipboard";
      After = "graphical-session.target";
    };
    Install = {
      WantedBy = [ config.wayland.systemd.target ];
    };
  };
}
