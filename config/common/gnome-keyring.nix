{
  config,
  lib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  enable = true;
in
lib.mkIf enable {
  home.packages = [
    pkgs.libsecret
    # pkgs.seahorse
  ];
  services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
  programs.git.settings.credential.helper = lib.getExe pkgsFrom.fym998-nur.git-credential-libsecret;
}
