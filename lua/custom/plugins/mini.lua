-- [[ mini.nvim ]]
--  A collection of various small independent plugins/modules
vim.pack.add { 'https://github.com/nvim-mini/mini.nvim' }

-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup {
  -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup()

-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local statusline = require 'mini.statusline'
-- Set `use_icons` to true if you have a Nerd Font
statusline.setup { use_icons = vim.g.have_nerd_font }

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- Dim the directory part of the filename so the filename itself stands
-- out; also shorten the directory to be relative to the cwd instead of
-- always printing the full absolute path.
vim.api.nvim_set_hl(0, 'MiniStatuslineFilenameDir', { link = 'Comment', default = true })
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_filename = function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then return '[No Name]' end

  -- `:~` shortens $HOME to `~`, `:.` makes it relative to cwd (falls back
  -- to absolute if the file isn't under cwd), `:h` drops the filename.
  local dir = vim.fn.fnamemodify(path, ':~:.:h')
  local tail = vim.fn.fnamemodify(path, ':t')

  local sep = package.config:sub(1, 1) -- OS path separator, matches what fnamemodify already used in `dir`
  local dir_part = (dir == '.' or dir == '') and '' or ('%#MiniStatuslineFilenameDir#' .. dir .. sep)
  return dir_part .. '%#MiniStatuslineFilename#' .. tail .. '%m%r'
end

-- ... and there is more!
--  Check out: https://github.com/nvim-mini/mini.nvim
