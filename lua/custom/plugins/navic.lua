-- Always-on breadcrumb (winbar) showing the class/method the cursor is
-- currently inside, driven by each LSP's document symbols.
vim.pack.add { 'https://github.com/SmiteshP/nvim-navic' }
require('nvim-navic').setup {
  separator = ' > ',
  highlight = true,
  depth_limit = 5,
  -- .vue buffers get both vue_ls and ts_ls; navic can only follow one.
  lsp = { auto_attach = true, preference = { 'vue_ls', 'ts_ls' } },
}
vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
