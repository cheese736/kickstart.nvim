-- Inline test runner: run/debug individual xUnit/NUnit/MSTest tests without
-- leaving the buffer, similar to Visual Studio's Test Explorer.
-- plenary.nvim and nvim-nio are already installed as dependencies of
-- telescope.nvim and nvim-dap-ui respectively.

vim.pack.add {
  'https://github.com/nvim-neotest/neotest',
  'https://github.com/Issafalcon/neotest-dotnet',
}

require('neotest').setup {
  adapters = {
    -- adapter_name matches the `coreclr` dap adapter registered in kickstart.plugins.debug
    require 'neotest-dotnet' { dap = { adapter_name = 'coreclr' } },
  },
}

-- `<leader>t` was declared as a "[T]oggle" which-key group with no keymaps
-- under it yet, so repurpose it for tests.
require('which-key').add { { '<leader>t', group = '[T]est' } }

local neotest = require 'neotest'
vim.keymap.set('n', '<leader>tr', function() neotest.run.run() end, { desc = '[T]est [R]un nearest' })
vim.keymap.set('n', '<leader>tf', function() neotest.run.run(vim.fn.expand '%') end, { desc = '[T]est run [F]ile' })
vim.keymap.set('n', '<leader>td', function() neotest.run.run { strategy = 'dap' } end, { desc = '[T]est [D]ebug nearest' })
vim.keymap.set('n', '<leader>ts', function() neotest.summary.toggle() end, { desc = '[T]est [S]ummary' })
vim.keymap.set('n', '<leader>to', function() neotest.output.open { enter = true } end, { desc = '[T]est [O]utput' })
