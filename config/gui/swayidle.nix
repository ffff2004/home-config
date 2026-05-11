{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.swayidle =
    let
      lockScreen = config.lib.genericLinux.getCmd pkgs.swaylock "swaylock -f -F";
      lockKeyring = "${lib.getExe pkgs.libsecret} lock";
      lockSession = lib.getExe (
        pkgs.writeShellScriptBin "lock-session" ''
          ${lockKeyring} || true
          SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh" ${lib.getExe' pkgs.openssh "ssh-add"} -D || true
          exec ${lockScreen} "$@"
        ''
      );
      signalNoctalia =
        signal:
        lib.getExe (
          pkgs.writeShellScriptBin "signal-noctalia-shell-${signal}" ''
            configPath=${lib.escapeShellArg "${config.programs.noctalia-shell.package}/share/noctalia-shell"}

            for environ in /proc/[0-9]*/environ; do
              if ${lib.getExe pkgs.gnugrep} -zqx "QS_CONFIG_PATH=$configPath" "$environ" 2>/dev/null; then
                pid="''${environ#/proc/}"
                pid="''${pid%/environ}"
                kill -${signal} "$pid" 2>/dev/null || true
              fi
            done
          ''
        );
      pauseNoctalia = signalNoctalia "STOP";
      resumeNoctalia = signalNoctalia "CONT";
      powerOffMonitors = config.lib.genericLinux.getCmd config.programs.niri.package "niri msg action power-off-monitors";
      sleep = config.lib.genericLinux.getCmd pkgs.systemd "systemctl suspend";
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 900;
          command = powerOffMonitors;
        }
      ]
      ++ lib.optionals config.programs.noctalia-shell.enable [
        {
          timeout = 900;
          command = pauseNoctalia;
          resumeCommand = resumeNoctalia;
        }
      ]
      ++ [
        {
          timeout = 1200;
          command = lockSession;
        }
        {
          timeout = 28800;
          command = sleep;
        }
      ];
      events = {
        before-sleep = lockSession;
      };
    };
}
