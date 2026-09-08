-- Supermaven: cloud-backed ghost-text completion, replacing the role
-- copilot.lua used to fill (now fully disabled — see that file). Reuses the
-- insert-mode keys Copilot's disabling freed up, since blink.cmp already
-- claims <Tab> (its own accept/snippet-forward/Roslyn-fallback chain) and
-- Supermaven's own default keymaps also default to <Tab>.
--
-- <Tab> still accepts Supermaven's suggestion, though: init.lua's blink.cmp
-- <Tab> chain calls into supermaven-nvim.completion_preview directly (after
-- its own menu and Roslyn's inline_completion, before snippet_forward).
-- accept_suggestion below is just a backup entry point, independent of that.

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
