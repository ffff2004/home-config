{
  config,
  lib,
  options,
  pkgs,
  pkgsFrom,
  ...
}:
let
  enable = true;
  hasLockSessionHooks = lib.hasAttrByPath [ "local" "gui" "lockSession" "preLockCommands" ] options;
  sshAuthSock = "$XDG_RUNTIME_DIR/gcr/ssh";
  busctl = config.lib.genericLinux.getCmd pkgs.systemd "busctl";
  mkdir = lib.getExe' pkgs.coreutils "mkdir";
  chmod = lib.getExe' pkgs.coreutils "chmod";
in
lib.mkIf enable (lib.mkMerge [
  {
    home.packages = [
      pkgs.gcr_4
      pkgs.libsecret
      # pkgs.seahorse
    ];

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };

    sshAuthSock.initialization = {
      bash = ''export SSH_AUTH_SOCK="${sshAuthSock}"'';
      fish = ''set -x SSH_AUTH_SOCK "${sshAuthSock}"'';
      nushell = ''$env.SSH_AUTH_SOCK = "${sshAuthSock}"'';
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".AddKeysToAgent = "yes";
    };

    systemd.user = {
      services.gcr-ssh-agent = {
        Unit = {
          Description = "GCR SSH agent";
          Requires = [ "gcr-ssh-agent.socket" ];
        };

        Service = {
          Type = "simple";
          StandardError = "journal";
          Environment = "SSH_AUTH_SOCK=%t/gcr/ssh";
          ExecStart = "${pkgs.gcr_4}/libexec/gcr-ssh-agent --base-dir %t/gcr";
          Restart = "on-failure";
        };

        Install = {
          Also = [ "gcr-ssh-agent.socket" ];
          WantedBy = [ "default.target" ];
        };
      };

      sockets.gcr-ssh-agent = {
        Unit.Description = "GCR SSH agent socket";

        Socket = {
          Priority = 6;
          Backlog = 5;
          ListenStream = "%t/gcr/ssh";
          ExecStartPost = "-${config.lib.genericLinux.getCmd pkgs.systemd "systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh"}";
          DirectoryMode = "0700";
        };

        Install.WantedBy = [ "sockets.target" ];
      };
    };

    programs.git.settings.credential.helper = lib.getExe pkgsFrom.fym998-nur.git-credential-libsecret;

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

  (lib.optionalAttrs hasLockSessionHooks {
    local.gui.lockSession.preLockCommands = [
      "${lib.getExe pkgs.libsecret} lock || true"
      ''SSH_AUTH_SOCK="${sshAuthSock}" ${lib.getExe' pkgs.openssh "ssh-add"} -D || true''
    ];
  })
])
