{
  imports = [ ./packages ];

  xdg.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  # programs.fzf.enable = true;
}
