{
  lib,
  pkgsFrom,
  ...
}:
{
  services.gpg-agent = {
    enable = true;
    pinentry.package = lib.mkDefault pkgsFrom.self.pinentry-auto;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
  programs.gpg.enable = true;
}
