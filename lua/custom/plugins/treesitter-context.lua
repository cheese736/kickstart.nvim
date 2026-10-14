-- [[ Sticky context ]]
--  Pins the enclosing function/class signature to the top of the window
--  when it scrolls out of view, so you always know which member the
--  cursor is currently inside.
vim.pack.add { 'https://github.com/nvim-treesitter/nvim-treesitter-context' }
require('treesitter-context').setup { max_lines = 3 }
