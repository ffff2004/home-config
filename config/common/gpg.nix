{
  lib,
  pkgs,
  ...
}:
{
  services.gpg-agent = {
    enable = true;
    pinentry.package = lib.mkDefault pkgs.pinentry-curses;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
  programs.gpg.enable = true;
}
