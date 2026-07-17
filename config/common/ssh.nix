{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*".AddKeysToAgent = "yes";

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
    };
  };

  services.ssh-agent.enable = lib.mkDefault true;
}
