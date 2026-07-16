{
  imports = [ ./packages.nix ];

  xdg.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.yazi = {
    enable = true;
  };

  programs.fzf.enable = true;

  programs.fd.enable = true;

  programs.ripgrep.enable = true;
}
