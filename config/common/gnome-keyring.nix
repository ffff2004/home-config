{
  config,
  lib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  enable = true;
  sshAuthSock = "$XDG_RUNTIME_DIR/gcr/ssh";
in
lib.mkIf enable {
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
}
