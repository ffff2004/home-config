{
  lib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  target = "niri.service";
  clipboardBridge = pkgsFrom.self.clipboard-bridge;
in
{
  systemd.user.services = {
    clipboard-bridge = {
      Service = {
        Type = "exec";
        ExecStart = "${clipboardBridge}/bin/clipboard-bridge daemon";
      };
      Unit = {
        Description = "Bridge Wayland and X11 clipboards";
        Documentation = builtins.concatStringsSep " " (
          map (dep: dep.meta.homepage or "") (
            with pkgs;
            [
              clipnotify
              wl-clipboard
              xclip
            ]
          )
        );
        After = target;
      };
    };
  };
}
