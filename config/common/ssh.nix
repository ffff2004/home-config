{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*".AddKeysToAgent = "yes";
      "*".ControlMaster = "auto";
      "*".ControlPersist = "10m";
      "*".ControlPath = "~/.ssh/cm-%C";

      fujun = {
        HostName = "fujun";
        User = "fujun";
      };

      fujun-wsl = {
        HostName = "127.0.0.1";
        User = "fym";
        Port = 2222;
        ProxyJump = "fujun";
      };

      legion-neoarch-nixcache = {
        HostName = "legion-neoarch";
        User = "nixcache";
        IdentityFile = "~/.ssh/id_ed25519-nixcache";
        IdentitiesOnly = "yes";
      };
    };
  };

  services.ssh-agent.enable = lib.mkDefault true;
}
