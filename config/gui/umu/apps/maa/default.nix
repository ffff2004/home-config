{
  config,
  lib,
  pkgs,
  ...
}:
let
  maaPath = "$HOME/Games/maa";
  pkg = pkgs.callPackage ./maa-proton.nix {
    inherit maaPath;
    umu-launcher-wrapper = config.umu.eval.packages.ge-wl;
  };
in
{
  home.packages = [ pkg ];

  systemd.user.services.arknights-maa = {
    Unit = {
      Description = "Launch Arknights via Waydroid and start MAA";
      After = [ config.wayland.systemd.target ];
      Requires = [ config.wayland.systemd.target ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe pkg;
    };
  };

  systemd.user.timers.arknights-maa = {
    Unit = {
      Description = "Run Arknights MAA daily";
    };
    Timer = {
      OnCalendar = "*-*-* 08,20:00:00";
      Persistent = false;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
