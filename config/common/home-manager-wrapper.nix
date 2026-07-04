{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeManager = lib.getExe config.programs.home-manager.package;

  mkHomeManagerWrapper =
    name: command: extraArgs:
    pkgs.writeShellScriptBin name ''
      set -eu

      is_wsl() {
        if [ -r /proc/sys/kernel/osrelease ]; then
          grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease
        else
          return 1
        fi
      }

      is_wayland_session() {
        if is_wsl; then
          return 1
        fi

        if [ "''${XDG_SESSION_TYPE:-}" = wayland ]; then
          return 0
        fi

        if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
          [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]
        else
          return 1
        fi
      }

      if is_wayland_session; then
        profile=fym
      else
        profile=fym-tty
      fi

      exec ${homeManager} ${command} --flake ".#$profile" ${extraArgs} "$@"
    '';
in
{
  home.packages = [
    (mkHomeManagerWrapper "hmb" "build" "")
    (mkHomeManagerWrapper "hmbo" "build" "--option substitute false")
    (mkHomeManagerWrapper "hms" "switch" "-b hmbak")
    (mkHomeManagerWrapper "hmso" "switch" "-b hmbak --option substitute false")
  ];
}
