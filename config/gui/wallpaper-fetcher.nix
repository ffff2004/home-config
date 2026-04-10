{
  config,
  lib,
  pkgsFrom,
  ...
}:
{
  systemd.user.services.wallpaper-fetcher = {
    Service = {
      ExecStart = "${pkgsFrom.fym998-nur.wallpaper-fetcher}/bin/wallpaper-fetcher -d --debug";
    };
  };
  systemd.user.timers.wallpaper-fetcher = {
    Install = {
      WantedBy = [ config.wayland.systemd.target ];
    };
    Timer = {
      OnActiveSec = "1min";
      OnUnitActiveSec = "1day";
    };
  };
}
