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
    # clipboard-bridge-wl-to-x11 =
    #   {
    #     Service = {
    #       Type = "exec";
    #       ExecStart = "${clipboardBridge}/bin/clipboard-bridge-wl-to-x11";
    #     };
    #     Unit = {
    #       Description = "Bridge Wayland clipboard to X11";
    #       Documentation = builtins.concatStringsSep " " (
    #         map (dep: dep.meta.homepage or "") (
    #           with pkgs;
    #           [
    #             wl-clipboard
    #             xclip
    #           ]
    #         )
    #       );
    #       After = target;
    #     };
    #     Install = {
    #       WantedBy = [ target ];
    #     };
    #   };
    clipboard-bridge-x11-to-wl = {
      Service = {
        Type = "exec";
        ExecStart = "${clipboardBridge}/bin/clipboard-bridge-x11-to-wl";
      };
      Unit = {
        Description = "Bridge X11 clipboard to Wayland";
        Documentation = builtins.concatStringsSep " " (
          map (dep: dep.meta.homepage or "") (
            with pkgs;
            [
              clipnotify
              xclip
              wl-clipboard
            ]
          )
        );
        After = target;
      };
      Install = {
        WantedBy = [ target ];
      };
    };
  };
}
