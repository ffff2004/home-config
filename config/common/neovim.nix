{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = ''
      set clipboard=unnamedplus
    '';
    coc = {
      enable = true;
      settings = {
        languageserver = {
          nix = {
            command = lib.getExe pkgs.nil;
            filetypes = [ "nix" ];
            rootPatterns = [ "flake.nix" ];
            settings = {
              nil = {
                formatting = {
                  command = [ (lib.getExe pkgs.nixfmt) ];
                };
              };
            };
          };
        };
      };
    };
  };
}
