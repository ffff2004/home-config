{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    initLua = ''
      vim.opt.clipboard = 'unnamed,unnamedplus'
      vim.opt.termguicolors = true

      vim.opt.hlsearch = true    -- 高亮所有匹配项
      vim.opt.incsearch = true   -- 输入时实时预览匹配位置
      vim.opt.ignorecase = true  -- 搜索忽略大小写
      vim.opt.smartcase = true   -- 若输入包含大写字母，则区分大小写

      vim.g.mapleader = " "
      vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
        if vim.fn.mode() == 'i' then
          vim.cmd.stopinsert()
        end
        vim.lsp.buf.format()
      end, { desc = 'Format code' })

      local function copy_current_file_path(modifier, label)
        local path = vim.fn.expand(modifier)
        vim.fn.setreg("+", path)
        vim.notify("Copied " .. label .. ": " .. path, vim.log.levels.INFO)
      end

      vim.keymap.set("n", "<leader>yr", function()
        copy_current_file_path("%:p:.", "relative path")
      end, { desc = "Copy relative file path" })

      vim.keymap.set("n", "<leader>ya", function()
        copy_current_file_path("%:p", "absolute path")
      end, { desc = "Copy absolute file path" })
    '';
    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nui-nvim
      nvim-web-devicons
      {
        plugin = bufferline-nvim;
        config = ''
          require("bufferline").setup({
            options = {
              diagnostics = "nvim_lsp",
            },
          })
        '';
      }
      {
        plugin = neo-tree-nvim;
        config = ''
          vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
          require("neo-tree").setup({
            window = {
              width = 30,
            },
            filesystem = {
              use_libuv_file_watcher = true,
              follow_current_file = {
                enabled = true,
              },
            },
          })
        '';
      }
      {
        plugin = toggleterm-nvim;
        config = ''
          require("toggleterm").setup({
            start_in_insert = true,
            direction = 'horizontal'
          })
          vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<CR>", { desc = "Toggle Terminal" })
        '';
      }
      {
        plugin = which-key-nvim;
        config = ''
          require("which-key").setup({
            preset = "modern"
          })
        '';
      }
      {
        plugin = telescope-nvim;
        config = ''
          local telescope = require("telescope")
          local builtin = require("telescope.builtin")

          telescope.setup({
            defaults = {
              mappings = {
                i = {
                  ["<C-u>"] = false,
                  ["<C-d>"] = false,
                },
              },
            },
          })

          vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
          vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
          vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
          vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
          vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
          vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "LSP References" })
        '';
      }
      {
        plugin = lualine-nvim;
        config = ''
          require("lualine").setup()
        '';
      }
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp_luasnip
      cmp-nvim-lsp
      friendly-snippets
      luasnip
      {
        plugin = nvim-cmp;
        config = ''
          local cmp = require("cmp")
          local luasnip = require("luasnip")

          require("luasnip.loaders.from_vscode").lazy_load()

          vim.opt.completeopt = { "menu", "menuone", "noselect" }

          cmp.setup({
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<CR>"] = cmp.mapping.confirm({ select = true }),
              ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { "i", "s" }),
              ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "luasnip" },
              { name = "path" },
              { name = "buffer" },
            }),
          })

          -- command-line mode completion for search (/)
          cmp.setup.cmdline('/', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = 'buffer' },
            },
          })

          -- command-line mode completion for commands (:)
          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'path' },
            }, {
              { name = 'cmdline' },
            }),
          })
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          local capabilities = require("cmp_nvim_lsp").default_capabilities()

          vim.lsp.config("nil_ls", {
            cmd = { "${lib.getExe pkgs.nil}" },
            capabilities = capabilities,
          })
          vim.lsp.enable("nil_ls")

          vim.lsp.config('ruff', {
            cmd = { "${lib.getExe pkgs.ruff}", "server" },
            capabilities = capabilities,
          })
          vim.lsp.enable('ruff')

          vim.lsp.config('bashls', {
            cmd = { "${lib.getExe pkgs.bash-language-server}", "start" },
            capabilities = capabilities,
          })
          vim.lsp.enable('bashls')

          vim.lsp.config('fish_lsp', {
            cmd = { "${lib.getExe pkgs.fish-lsp}", "start" },
            capabilities = capabilities,
          })
          vim.lsp.enable('fish_lsp')
        '';
      }
    ];
  };
}
