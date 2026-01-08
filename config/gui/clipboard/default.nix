{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = pkgs.stdenvNoCC.shell;
  inherit (config.wayland.systemd) target;
in
{
  systemd.user.services = {
    clipboard-bridge-wl-to-x11 =
      let
        deps = [
          pkgs.wl-clipboard
          pkgs.xclip
        ];
      in
      {
        Service = {
          Type = "exec";
          ExecStart = "wl-paste --watch ${shell} ${./bridge-wl-to-x11.sh}";
          Environment = "PATH=${lib.makeBinPath deps}";
        };
        Unit = {
          Description = "Bridge Wayland clipboard to X11";
          Documentation = builtins.concatStringsSep " " (map (dep: dep.meta.homepage or "") deps);
          After = target;
        };
        Install = {
          WantedBy = [ target ];
        };
      };
    clipboard-bridge-x11-to-wl =
      let
        deps = [
          pkgs.wl-clipboard
          pkgs.xclip
          pkgs.clipnotify
          pkgs.diffutils
        ];
      in
      {
        Service = {
          Type = "exec";
          ExecStart = "${shell} ${./bridge-x11-to-wl.sh}";
          Environment = "PATH=${lib.makeBinPath deps}";
        };
        Unit = {
          Description = "Bridge X11 clipboard to Wayland";
          Documentation = builtins.concatStringsSep " " (map (dep: dep.meta.homepage or "") deps);
          After = target;
        };
        Install = {
          WantedBy = [ target ];
        };
      };
  };
}
