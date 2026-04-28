{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = ''
      set clipboard=unnamedplus
    '';

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nui-nvim
      nvim-web-devicons
      {
        plugin = bufferline-nvim;
        type = "lua";
        config = ''
          vim.opt.termguicolors = true
          require("bufferline").setup({})
        '';
      }
      {
        plugin = neo-tree-nvim;
        type = "lua";
        config = ''
          vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
        '';
      }
      {
        plugin = toggleterm-nvim;
        type = "lua";
        config = ''
          require("toggleterm").setup({
            open_mapping = [[<C-`>]],
            start_in_insert = true,
            direction = 'horizontal'
          })
        '';
      }
    ];
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
