{
  config,
  lib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  busctl = config.lib.genericLinux.getCmd pkgs.systemd "busctl";
  mkdir = lib.getExe' pkgs.coreutils "mkdir";
  chmod = lib.getExe' pkgs.coreutils "chmod";
in
{
  home.packages = [
    pkgs.libsecret
    pkgs.seahorse
  ];

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  programs.git.settings.credential.helper = lib.getExe pkgsFrom.fym998-nur.git-credential-libsecret;

  local.gui.lockSession.preLockCommands = [
    "${lib.getExe pkgs.libsecret} lock || true"
  ];

  home.activation.gnomeKeyringDefaultCollection = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    keyrings_dir="${config.xdg.dataHome}/keyrings"
    default_file="$keyrings_dir/default"
    login_collection="/org/freedesktop/secrets/collection/login"

    # PAM unlocks the canonical "login" collection path. If Secret Service's
    # default alias drifts to a duplicate collection such as login_1, pinentry
    # saves GPG passphrases into a keyring that password login does not unlock.
    if [ -n "''${DBUS_SESSION_BUS_ADDRESS-}" ]; then
      run --silence ${busctl} --user call org.freedesktop.secrets \
        /org/freedesktop/secrets \
        org.freedesktop.Secret.Service \
        SetAlias so default "$login_collection" || true
    fi

    # Keep gnome-keyring's persistent alias file aligned for the next daemon
    # start. This is mutable keyring state, not a Home Manager managed dataFile:
    # the surrounding keyrings directory contains encrypted secret databases.
    if [ -n "''${DRY_RUN-}" ]; then
      echo "Would ensure $default_file points to login"
    else
      ${mkdir} -p "$keyrings_dir"
      printf 'login' > "$default_file"
      ${chmod} 0644 "$default_file"
    fi
  '';
}
