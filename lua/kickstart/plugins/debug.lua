-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  'https://github.com/leoluz/nvim-dap-go',
}

-- Basic debugging keymaps, feel free to change to your liking!
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F9>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
vim.keymap.set('n', '<leader>dx', function() require('dap').terminate() end, { desc = 'Debug: Stop' })
vim.keymap.set('n', '<leader>dX', function() require('dap').clear_breakpoints() end, { desc = 'Debug: Clear all breakpoints' })
-- 跳回目前停下的 frame（看別的檔案後回到執行位置）
vim.keymap.set('n', '<leader>dc', function() require('dap').focus_frame() end, { desc = 'Debug: Go to current frame' })

-- dapui 不自動開啟，需要時以畫面中央浮動視窗顯示變數（scopes）；在視窗內按 q / <Esc> 關閉。
-- 需要有進行中的 debug session，否則 dapui 會提示 No active debug session。
local function toggle_dapui_float()
  require('dapui').float_element('scopes', {
    width = math.floor(vim.o.columns * 0.6),
    height = math.floor(vim.o.lines * 0.6),
    enter = true,
    position = 'center',
  })
end
vim.keymap.set('n', '<F7>', toggle_dapui_float, { desc = 'Debug: Variables (float)' })

local dap = require 'dap'
local dapui = require 'dapui'

require('mason-nvim-dap').setup {
  -- Makes a best effort to setup the various debuggers with
  -- reasonable debug configurations
  automatic_installation = true,

  -- You can provide additional configuration to the handlers,
  -- see mason-nvim-dap README for more information
  handlers = {},

  -- You'll need to check that you have the required things installed
  -- online, please don't ask me how to install them :)
  ensure_installed = {
    -- Update this to ensure that you have the debuggers for the langs you want
    -- 'delve',
    'netcoredbg',
  },
}

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
---@diagnostic disable-next-line: missing-fields
dapui.setup {
  -- Set icons to characters that are more likely to work in every terminal.
  --    Feel free to remove or use ones that you like more! :)
  --    Don't feel like these are good choices.
  -- icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  ---@diagnostic disable-next-line: missing-fields
  -- controls = {
  --   icons = {
  --     pause = '⏸',
  --     play = '▶',
  --     step_into = '⏎',
  --     step_over = '⏭',
  --     step_out = '⏮',
  --     step_back = 'b',
  --     run_last = '▶▶',
  --     terminate = '⏹',
  --     disconnect = '⏏',
  --   },
  -- },

  -- ramboe's minimal ui, see https://www.youtube.com/watch?v=UCA_OqPvBrs
  expand_lines = true,
  floating = { border = 'rounded' },

  -- Set dapui window
  render = {
    max_type_length = 60,
    max_value_lines = 200,
  },
  -- Only one layout: just the "scope" (variables) list at the bottom
  layouts = {
    {
      elements = {
        { id = 'scopes', size = 1.0 },
      },
      size = 15,
      position = 'bottom',
    },
  },
}

vim.keymap.set('n', '<leader>du', toggle_dapui_float, { desc = 'DAP UI (float)' })
vim.keymap.set({ 'n', 'v' }, '<leader>de', function() dapui.eval(nil, { enter = true }) end, { desc = 'DAP Add word under cursor to Watches' })
vim.keymap.set({ 'n', 'v' }, 'Q', function() dapui.eval() end, { desc = 'DAP Peek' })

-- Change breakpoint icons
vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
local breakpoint_icons = vim.g.have_nerd_font
    and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
  or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
for type, icon in pairs(breakpoint_icons) do
  local tp = 'Dap' .. type
  local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
  vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

-- 不在 event_initialized 自動開 dapui（改用 F7 / <leader>du 手動開浮動視窗），結束時仍收掉殘留視窗。
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- Floating key-hint window shown while a debug session is active
local hint_lines = {
  ' F5          Continue      ',
  ' F10         Step Over     ',
  ' F11         Step Into     ',
  ' F9          Step Out      ',
  ' F7          Variables     ',
  ' <leader>b   Toggle break  ',
  ' <leader>dc  Go to current ',
  ' <leader>dx  Stop          ',
  ' <leader>dX  Clear breaks  ',
  ' <leader>du  Variables     ',
  ' <leader>de  Add Watches   ',
  ' Q           Peek          ',
}
-- 寬度取最長一行的顯示寬度，避免長行被截；高度隨行數，但不超出畫面。
local hint_width = 0
for _, l in ipairs(hint_lines) do
  hint_width = math.max(hint_width, vim.fn.strdisplaywidth(l))
end
local hint_buf, hint_win

local function hint_config()
  return {
    relative = 'editor',
    anchor = 'NE',
    row = 1,
    col = vim.o.columns - 1,
    width = hint_width,
    height = math.max(1, math.min(#hint_lines, vim.o.lines - 4)),
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 40,
  }
end

local function close_hints()
  if hint_win and vim.api.nvim_win_is_valid(hint_win) then
    vim.api.nvim_win_close(hint_win, true)
  end
  hint_win = nil
end

local function open_hints()
  if hint_win and vim.api.nvim_win_is_valid(hint_win) then
    return
  end
  if not (hint_buf and vim.api.nvim_buf_is_valid(hint_buf)) then
    hint_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(hint_buf, 0, -1, false, hint_lines)
    vim.bo[hint_buf].modifiable = false
  end
  hint_win = vim.api.nvim_open_win(hint_buf, false, hint_config())
end

dap.listeners.after.event_initialized['dap_hints'] = open_hints
dap.listeners.before.event_terminated['dap_hints'] = close_hints
dap.listeners.before.event_exited['dap_hints'] = close_hints
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    if hint_win and vim.api.nvim_win_is_valid(hint_win) then
      vim.api.nvim_win_set_config(hint_win, hint_config())
    end
  end,
})

-- Install golang specific config
-- require('dap-go').setup {
  -- delve = {
    -- On Windows delve must be run attached or it crashes.
    -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
--     detached = vim.fn.has 'win32' == 0,
--   },
-- }


dap.adapters.coreclr = {
  type = 'executable',
  command = vim.fs.joinpath(
    vim.fn.stdpath 'data',
    'mason', 'packages', 'netcoredbg', 'netcoredbg',
    'netcoredbg' .. (vim.fn.has 'win32' == 1 and '.exe' or '')
  ),
  args = { '--interpreter=vscode' },
}

dap.configurations.cs = {
  {
    type = 'coreclr',
    name = 'launch - netcoredbg',
    request = 'launch',
    -- netcoredbg 不會套用 launchSettings.json，這裡手動讀 https profile 的網址，避免退回預設 port 5000。
    env = function()
      local env = { ASPNETCORE_ENVIRONMENT = 'Development' }
      local path = vim.fn.getcwd() .. '/Properties/launchSettings.json'
      if vim.uv.fs_stat(path) then
        local ok, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
        local profile = ok and json.profiles and json.profiles.https
        if profile and profile.applicationUrl then env.ASPNETCORE_URLS = profile.applicationUrl end
      end
      return env
    end,
    program = function()
      -- F5 前先建置，避免 bin 內是舊 dll 導致中斷點綁不上。
      vim.notify 'dotnet build...'
      local build = vim.system({ 'dotnet', 'build', '-c', 'Debug', '-v', 'q' }, { text = true }):wait()
      if build.code ~= 0 then
        vim.notify('dotnet build 失敗:\n' .. (build.stdout or ''), vim.log.levels.ERROR)
        return dap.ABORT
      end
      local dlls = vim.fn.glob(vim.fn.getcwd() .. '/bin/Debug/**/*.dll', true, true)
      if #dlls == 1 then
        return dlls[1]
      end

      return coroutine.create(function(dap_run_co)
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'

        local function on_select(path)
          coroutine.resume(dap_run_co, path)
        end

        local attach_mappings = function(prompt_bufnr, map)
          local function choose()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            on_select(selection and (selection.path or selection.value) or nil)
          end
          actions.select_default:replace(choose)
          map({ 'i', 'n' }, '<esc>', function()
            actions.close(prompt_bufnr)
            on_select(nil)
          end)
          return true
        end

        if #dlls > 1 then
          require('telescope.pickers').new({}, {
            prompt_title = 'Select .dll to debug',
            finder = require('telescope.finders').new_table { results = dlls },
            sorter = require('telescope.config').values.generic_sorter {},
            attach_mappings = attach_mappings,
          }):find()
        else
          require('telescope.builtin').find_files {
            prompt_title = 'Locate .dll to debug',
            cwd = vim.fn.getcwd() .. '/bin',
            attach_mappings = attach_mappings,
          }
        end
      end)
    end,
  },
}
