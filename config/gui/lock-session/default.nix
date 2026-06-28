{
  config,
  lib,
  pkgs,
  ...
}:
let
  configHome = config.xdg.configHome;
  swaylockConfig = "${configHome}/swaylock/themes/matugen.conf";
  lockScreen = config.lib.genericLinux.getCmd pkgs.swaylock "swaylock";
  preLockCommands = lib.concatStringsSep "\n" config.local.gui.lockSession.preLockCommands;
  lockSession = pkgs.writeShellScriptBin "lock-session" ''
    ${preLockCommands}

    swaylock_config=${lib.escapeShellArg swaylockConfig}
    if [ -f "$swaylock_config" ]; then
      exec ${lockScreen} -f -F --config "$swaylock_config" "$@"
    fi

    exec ${lockScreen} -f -F "$@"
  '';
in
{
  options.local.gui.lockSession = {
    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Command that runs pre-lock hooks and locks the screen.";
    };

    preLockCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Shell commands to run before locking the screen.";
    };
  };

  config = {
    home.packages = [ lockSession ];
    local.gui.lockSession.command = lib.getExe lockSession;
    local.gui.theme.templates.swaylock = {
      # Source: config/gui/noctalia-shell/user-templates/swaylock.conf
      inputPath = ./swaylock.conf;
      outputPath = swaylockConfig;
    };
  };
}
