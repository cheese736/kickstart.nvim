-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local plugins = {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons') -- not strictly required, but recommended
end

vim.pack.add(plugins)

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

local tfvc = require 'custom.tfvc'
local fs_commands = require 'neo-tree.sources.filesystem.commands'

local function tfvc_command(action)
  return function(state)
    local node = state.tree:get_node()
    tfvc[action](node.path, node.type, function()
      fs_commands.refresh(state)
    end)
  end
end

require('neo-tree').setup {
  window = {
    position = 'float',
  },
  source_selector = {
    winbar = true,
  },
  filesystem = {
    commands = {
      tfvc_checkout = tfvc_command 'checkout',
      tfvc_checkin = tfvc_command 'checkin',
      tfvc_undo = tfvc_command 'undo',
      tfvc_delete = tfvc_command 'delete',
      tfvc_status = tfvc_command 'status',
      tfvc_pending = function()
        require('custom.tfvc_pending').open()
      end,
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['T'] = { 'show_help', config = { title = 'TFVC', prefix_key = 'T' }, nowait = false },
        ['Tc'] = { 'tfvc_checkout', nowait = false },
        ['Ti'] = { 'tfvc_checkin', nowait = false },
        ['Tu'] = { 'tfvc_undo', nowait = false },
        ['Td'] = { 'tfvc_delete', nowait = false },
        ['Ts'] = { 'tfvc_status', nowait = false },
        ['Tp'] = { 'tfvc_pending', nowait = false },
      },
    },
  },
}
