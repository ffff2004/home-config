{
  config,
  lib,
  pkgs,
  ...
}:
let
  lockScreen = config.lib.genericLinux.getCmd pkgs.swaylock "swaylock -f -F";
  lockKeyring = "${lib.getExe pkgs.libsecret} lock";
  lockSession = pkgs.writeShellScriptBin "lock-session" ''
    ${lockKeyring} || true
    SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh" ${lib.getExe' pkgs.openssh "ssh-add"} -D || true
    exec ${lockScreen} "$@"
  '';
in
{
  options.local.gui.lockSession = {
    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Command that locks GNOME Keyring, clears the GCR SSH agent, and locks the screen.";
    };
  };

  config = {
    home.packages = [ lockSession ];
    local.gui.lockSession.command = lib.getExe lockSession;
  };
}
