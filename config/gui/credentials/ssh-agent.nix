{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshAuthSock = "$XDG_RUNTIME_DIR/gcr/ssh";
in
{
  services.ssh-agent.enable = false;

  home.packages = [ pkgs.gcr_4 ];

  sshAuthSock = {
    enable = true;
    systemd.socketProviderUnit = "gcr-ssh-agent.socket";
    initialization = {
      bash = ''export SSH_AUTH_SOCK="${sshAuthSock}"'';
      fish = ''set -x SSH_AUTH_SOCK "${sshAuthSock}"'';
      nushell = ''$env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/gcr/ssh"'';
    };
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

  local.gui.lockSession.preLockCommands = [
    ''SSH_AUTH_SOCK="${sshAuthSock}" ${lib.getExe' pkgs.openssh "ssh-add"} -D || true''
  ];
}
