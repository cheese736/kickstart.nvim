-- [[ Colorscheme ]]
-- You can easily change to a different colorscheme.
-- Change the name of the colorscheme plugin below, and then
-- change the command under that to load whatever the name of that colorscheme is.
--
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
vim.pack.add { 'https://github.com/folke/tokyonight.nvim' }
---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- Disable italics in comments
  },
}

-- Installed as an alternative to tokyonight — swap the `vim.cmd.colorscheme`
-- call below to 'catppuccin' (or a flavor variant) to switch to it.
vim.pack.add { 'https://github.com/catppuccin/nvim' }
require('catppuccin').setup {
  flavour = 'frappe', -- latte, frappe, macchiato, mocha
}

-- Load the colorscheme here.
-- Like many other themes, this one has different styles, and you could load
-- any other, such as 'tokyonight-storm', 'tokyonight-moon', 'tokyonight-day',
-- or 'catppuccin' (see flavour setting above).
vim.cmd.colorscheme 'catppuccin'
