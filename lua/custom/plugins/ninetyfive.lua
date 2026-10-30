-- NinetyFive: cloud-backed ghost-text completion, replacing Supermaven
-- (see supermaven.lua, currently commented out). Accept keys carried over
-- from Supermaven. <Tab> itself is NOT bound here -- blink.cmp's own <Tab>
-- keymap (blink.lua) checks NinetyFive's suggestion as a fallback so blink's
-- menu always wins priority. These are just extra direct-access keys.

vim.pack.add { 'https://github.com/numerataz/ninetyfive.nvim' }

require('ninetyfive').setup {
  -- No nvim-cmp here (blink.cmp instead); always render inline ghost text.
  use_cmp = false,
  -- All built-in mappings off: the plugin binds accept_word/accept_line/reject
  -- in normal mode too, which would clobber <C-l>/<C-j> window navigation
  -- (init.lua), and its `accept` (<Tab>) would fight blink.cmp's <Tab>.
  mappings = { accept = false, accept_word = false, accept_line = false, reject = false },
  -- Answer the indexing consent up front: the default 'ask' fires
  -- vim.ui.select during startup, before the initial buffer steals focus
  -- back, so its picker can't be confirmed (<CR> lands in the file instead).
  indexing = { mode = 'on' },
}

-- Same insert-mode keys Supermaven used.
vim.keymap.set('i', '<C-l>', '<Cmd>NinetyFiveAccept<CR>', { desc = 'NinetyFive: Accept suggestion' })
vim.keymap.set('i', '<C-]>', '<Cmd>NinetyFiveReject<CR>', { desc = 'NinetyFive: Clear suggestion' })
vim.keymap.set('i', '<C-j>', '<Cmd>NinetyFiveAcceptWord<CR>', { desc = 'NinetyFive: Accept word' })

-- Quick on/off switch (e.g. before screen-sharing), alongside the existing
-- Claude keymaps under the same "[A]I / Claude" which-key group.
vim.keymap.set('n', '<leader>at', '<cmd>NinetyFive<cr>', { desc = 'NinetyFive: Toggle suggestions' })
