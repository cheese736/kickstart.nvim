-- Useful plugin to show you pending keybinds.
vim.pack.add { 'https://github.com/folke/which-key.nvim' }
require('which-key').setup {
  -- Delay between pressing a key and opening which-key (milliseconds)
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  -- `<auto>` covers every other trigger via which-key's normal detection;
  -- `L` is added explicitly because which-key's auto-trigger scan refuses
  -- to shadow bare single-key builtins other than g/z/Z, and `L` (cursor
  -- to last line) doesn't qualify. Only activates where real `L*`
  -- keymaps exist (i.e. once an LSP attaches), so it's a no-op elsewhere.
  triggers = {
    { '<auto>', mode = 'nxso' },
    { 'L', mode = { 'n', 'x' } },
  },
  -- Document existing key chains
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    -- Bare `L` (no leader) rather than `<leader>l`: every submap below is
    -- buffer-local, only set once an LSP client attaches, so this only
    -- shadows the builtin `L` motion in buffers you're actively coding in.
    { 'L', group = '[L]SP Actions', mode = { 'n', 'x' } },
  },
}
