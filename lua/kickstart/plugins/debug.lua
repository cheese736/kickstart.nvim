-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

-- subst 磁碟路徑修正（讓 netcoredbg 中斷點綁得上）
--
-- 背景：W: 是用 `subst W: D:\Substitute\W` 建出來的虛擬磁碟。Visual Studio / dotnet build
-- 都是從 W:\ 建置，所以 PDB 裡記的原始碼路徑是 W:\...。
--
-- 問題：netcoredbg 用「路徑字串」比對中斷點與 PDB，只要前綴不同（D:\Substitute\W\ vs W:\）
-- 中斷點就永遠停在 pending。而 nvim 端有兩個地方會冒出真實路徑 D:\Substitute\W\...：
--   1. 終端機把起始目錄解成真實路徑 → getcwd() 是 D:\...，program 的 dll 路徑跟著變 D:\...
--   2. oldfiles 等來源記的是舊的 D:\... 路徑 → buffer 名稱是 D:\...，
--      而 nvim-dap 的 setBreakpoints 直接拿 buffer 名稱當 source.path 送出。
--
-- 已試過但無效：launch 設定的 sourceFileMap（兩個方向都試過），netcoredbg 不會用它來比對中斷點。
--
-- 做法：啟動時把 cwd 換回 W:，並在讀入檔案後把 D:\Substitute\W\... 的 buffer 改名為 W:\...。
do
  -- subst 背後的真實路徑前綴（結尾含反斜線，避免誤配到 D:\Substitute\Wxxx）
  local real_prefix = 'D:\\Substitute\\W\\'

  -- 把真實路徑轉成 W: 路徑；不在 real_prefix 底下的路徑回傳 nil。
  -- 先統一成反斜線、比對時忽略大小寫（Windows 路徑不分大小寫）。
  local function to_subst(path)
    local p = path:gsub('/', '\\')
    if p:lower():sub(1, #real_prefix) == real_prefix:lower() then return 'W:\\' .. p:sub(#real_prefix + 1) end
  end

  -- 1. 修正 cwd。補上結尾反斜線，讓剛好停在 D:\Substitute\W 本身時也能對上前綴。
  --    之後相對路徑開檔、dll 搜尋（program 裡的 getcwd()）都會是 W:\...。
  local cwd = to_subst((vim.uv.cwd() or '') .. '\\')
  if cwd then vim.cmd.cd { cwd, mods = { silent = true } } end

  -- 2. 修正 buffer 名稱。
  --    不能用 `:edit W:\...`：nvim 以檔案 ID 辨識 buffer，會認出 W: 與 D: 是同一個檔案而沿用原 buffer（名稱不變）。
  --    所以改用 `:file` 直接改名；但改名後 buffer 會被標成「檔名已變更」，下次 :w 會出現 E13，
  --    因此再 `:edit!` 從新路徑重讀一次，清掉這個狀態。
  --    例外：同一檔案的 W: buffer 已經開著時（例如先開了 W: 版，又從舊 oldfiles 開到 D: 版），
  --    nvim 會另建一個 D: buffer，此時 `:file W:\...` 會因同名 buffer 已存在（E95）而失敗，
  --    D: buffer 留下來、中斷點下在它身上就綁不上。所以這種情況改成切到既有的 W: buffer，再刪掉 D: buffer。
  local augroup = vim.api.nvim_create_augroup('subst-w-path', { clear = true })

  -- 找名稱等於 name 的 buffer（忽略大小寫）。不用 bufnr(name)，因為它把參數當檔名樣式比對，
  -- 反斜線與空白會被當成特殊字元。
  local function find_buf(name)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(b):lower() == name:lower() then return b end
    end
  end

  vim.api.nvim_create_autocmd('BufReadPost', {
    group = augroup,
    callback = function(ev)
      local new = to_subst(ev.match)
      if not new then return end
      -- 延後到讀檔流程結束再改名，避免在 BufReadPost 當下改動正在讀入的 buffer。
      vim.schedule(function()
        -- buffer 已關閉，或使用者已經開始編輯（:edit! 會丟掉修改）就不動它。
        if not vim.api.nvim_buf_is_valid(ev.buf) or vim.bo[ev.buf].modified then return end

        local existing = find_buf(new)
        if existing and existing ~= ev.buf then
          -- 已有 W: buffer：把顯示 D: buffer 的視窗都切過去，保留原本的游標位置，然後刪掉 D: buffer。
          for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
            local pos = vim.api.nvim_win_get_cursor(win)
            vim.api.nvim_win_set_buf(win, existing)
            pcall(vim.api.nvim_win_set_cursor, win, pos)
          end
          pcall(vim.api.nvim_buf_delete, ev.buf, {})
          return
        end

        vim.api.nvim_buf_call(ev.buf, function()
          -- :edit! 會重設游標與捲動位置，先存起來再還原。
          local view = vim.fn.winsaveview()
          -- keepalt：不要讓舊的 D: 名稱變成 alternate file（否則 <C-^> 會跳回 D: 路徑）。
          vim.cmd('keepalt file ' .. vim.fn.fnameescape(new))
          -- 重讀時會再觸發一次 BufReadPost，但 W: 路徑 to_subst() 回傳 nil，不會無限循環。
          vim.cmd 'silent edit!'
          vim.fn.winrestview(view)
        end)
      end)
    end,
  })

  -- 3. 修正最近檔案清單（v:oldfiles）。
  --    以前工作目錄在 D: 時留下的紀錄都是 D:\Substitute\W\...，從 <leader>s. 開就會開到 D: 路徑。
  --    shada 在 init.lua 跑完之後才讀入，所以要等 VimEnter 再改；改寫後順便去重（W: 與 D: 可能各有一筆），
  --    保留先出現的順序。之後存 shada 時，舊的 D: 紀錄就會被 W: 取代。
  vim.api.nvim_create_autocmd('VimEnter', {
    group = augroup,
    once = true,
    callback = function()
      local seen, files = {}, {}
      for _, f in ipairs(vim.v.oldfiles) do
        local p = to_subst(f) or f
        if not seen[p:lower()] then
          seen[p:lower()] = true
          files[#files + 1] = p
        end
      end
      vim.v.oldfiles = files
    end,
  })
end

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
  -- 診斷用：引擎 log 寫到 stdpath('cache')/netcoredbg.log，查完中斷點問題後可移除。
  args = { '--interpreter=vscode', '--engineLogging=' .. vim.fs.joinpath(vim.fn.stdpath 'cache', 'netcoredbg.log') },
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
