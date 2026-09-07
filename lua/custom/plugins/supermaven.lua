-- Supermaven: cloud-backed ghost-text completion, replacing Copilot
-- (see copilot.lua, currently commented out). Keeps Supermaven's default
-- always-on auto-suggest behavior (unlike Copilot's manual-trigger setup).
-- <Tab> itself is NOT bound here -- blink.cmp's own <Tab> keymap (init.lua)
-- checks Supermaven's suggestion as a fallback so blink's menu always wins
-- priority. These are just extra direct-access keys.

vim.pack.add { 'https://github.com/supermaven-inc/supermaven-nvim' }

require('supermaven-nvim').setup {
  keymaps = {
    accept_suggestion = '<C-l>',
    clear_suggestion = '<C-]>',
    accept_word = '<C-j>',
  },
}
