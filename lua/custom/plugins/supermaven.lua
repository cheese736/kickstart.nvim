-- Supermaven: cloud-backed ghost-text completion, replacing Copilot
-- (see copilot.lua, currently commented out). Keeps Supermaven's default
-- always-on auto-suggest behavior (unlike Copilot's manual-trigger setup).
-- <Tab> itself is NOT bound here -- blink.cmp's own <Tab> keymap (init.lua)
-- checks Supermaven's suggestion as a fallback so blink's menu always wins
-- priority. These are just extra direct-access keys.

vim.pack.add { 'https://github.com/supermaven-inc/supermaven-nvim' }

require('supermaven-nvim').setup {
  keymaps = {
    -- Backup accept key; Copilot's old accept/dismiss keys, unclaimed since 1d9d56c disabled it.
    accept_suggestion = '<C-l>',
    clear_suggestion = '<C-]>',
    accept_word = '<C-j>', -- default; not used elsewhere in this config
  },
  color = {
    -- Give Supermaven's ghost text its own identity, distinct from
    -- blink.cmp/Roslyn's default grey — catppuccin frappe's green.
    suggestion_color = '#a6d189',
  },
}

-- Quick on/off switch (e.g. before screen-sharing), alongside the existing
-- Claude keymaps under the same "[A]I / Claude" which-key group.
vim.keymap.set('n', '<leader>at', '<cmd>SupermavenToggle<cr>', { desc = 'Supermaven: Toggle suggestions' })
