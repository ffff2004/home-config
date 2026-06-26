{
  config,
  lib,
  pkgs,
  ...
}:
let
  lockScreen = config.lib.genericLinux.getCmd pkgs.swaylock "swaylock -f -F";
  preLockCommands = lib.concatStringsSep "\n" config.local.gui.lockSession.preLockCommands;
  lockSession = pkgs.writeShellScriptBin "lock-session" ''
    ${preLockCommands}
    exec ${lockScreen} "$@"
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
  };
}
