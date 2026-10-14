-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- rust_analyzer = {},
  --
  -- Some languages (like typescript) have entire language plugins that can be useful:
  --    https://github.com/pmizio/typescript-tools.nvim
  --
  -- But for many setups, the LSP (`ts_ls`) will work just fine
  -- ts_ls = {},

  -- NOTE: stylua is a formatter, not an LSP server, so it lives in the Mason
  -- `ensure_installed` list below (next to prettier) and is wired into
  -- conform's formatters_by_ft — not in this `servers` table.

  ts_ls = {
    init_options = {
      plugins = {
        {
          name = '@vue/typescript-plugin',
          location = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'vue-language-server', 'node_modules', '@vue', 'typescript-plugin'),
          languages = { 'vue' },
        },
      },
    },
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
  },

  vue_ls = {},

  pyright = {},

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
      },
    },
  },
}

vim.pack.add {
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- Automatically install LSPs and related tools to stdpath for Neovim
-- 官方 mason-registry 沒有真正的 Roslyn LSP 套件（只有不同專案的
-- csharp-language-server），實際能用的 `roslyn` 套件只在 Crashdummyy
-- 的自訂 registry 裡，執行檔會裝成 `roslyn.cmd`。
require('mason').setup {
  registries = {
    'github:Crashdummyy/mason-registry',
    'github:mason-org/mason-registry',
  },
}

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
-- Some lspconfig names differ from their mason package names, so filter them out
-- and add the correct mason package names explicitly below
local lspconfig_to_mason = {
  vue_ls = 'vue-language-server',
  ts_ls = 'typescript-language-server',
  lua_ls = 'lua-language-server',
}
local ensure_installed = vim.tbl_filter(function(n) return not lspconfig_to_mason[n] end, vim.tbl_keys(servers or {}))
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
  -- csharpier removed: not used for cs formatting anymore (see conform's
  -- formatters_by_ft — Roslyn LSP formatting is used instead), and Mason's
  -- self-contained build crashes on startup on this machine anyway.
  'prettier',
  'stylua', -- Lua formatter, invoked via conform's formatters_by_ft
  'lua-language-server',
  'vue-language-server',
  'typescript-language-server',
  'roslyn',
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
