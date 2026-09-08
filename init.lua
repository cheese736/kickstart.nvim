--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  --  See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  --  For more options, you can see `:help option-list`

  -- Make line numbers default
  vim.o.number = true
  -- You can also add relative line numbers, to help with jumping.
  --  Experiment for yourself to see if you like it!
  -- vim.o.relativenumber = true

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Enable code folding, defaulting to treesitter (falls back to no folds in
  -- buffers without an active parser); the kickstart-lsp-attach group below
  -- upgrades this per-window to LSP folding ranges when the attached client
  -- supports them (e.g. Roslyn's semantic folds for C#).
  vim.o.foldmethod = 'expr'
  vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.o.foldlevelstart = 99 -- start with every fold open

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Sets how neovim will display certain whitespace characters in the editor.
  --  See `:help 'list'`
  --  and `:help 'listchars'`
  --
  --  Notice listchars is set using `vim.opt` instead of `vim.o`.
  --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
  --   See `:help lua-options`
  --   and `:help lua-guide-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Auto-detect line ending format (unix/dos/mac) when opening a file,
  -- instead of assuming 'unix' and showing CRLF files with a trailing ^M.
  -- See `:help 'fileformats'`
  vim.opt.fileformats = { 'unix', 'dos', 'mac' }

  -- Some repos ship an .editorconfig with `end_of_line = lf`, but individual
  -- files (e.g. checked out via TFVC on Windows) can still be CRLF on disk.
  -- Neovim's builtin editorconfig support would otherwise force
  -- fileformat=unix on such files despite the CRLF content, undoing the
  -- autodetection above and bringing back the ^M. Let autodetection win;
  -- the rest of editorconfig (indent, charset, trim_trailing_whitespace...)
  -- is untouched. See `:help editorconfig-properties`
  require('editorconfig').properties.end_of_line = function() end

  -- .NET / TFVC 專案常見副檔名一律使用 CRLF，不受上面的自動偵測影響
  -- （例如 TFVC 簽出後的 buffer reload，若檔案混入裸 LF 行，自動偵測
  -- 會誤判整個 buffer 為 unix，存檔後把 CRLF 全部改成 LF）。
  -- 在讀檔前先設定 buffer-local 'fileformat'，可以讓 Neovim 跳過
  -- 'fileformats' 自動偵測，直接以 dos 格式讀寫（用法同上面 editorconfig
  -- monkeypatch 所繞過的內建行為）。See `:help 'fileformat'`
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    pattern = { '*.cs', '*.vb', '*.xml', '*.csproj', '*.vbproj', '*.sln', '*.config', '*.resx', '*.props', '*.targets' },
    callback = function(event)
      vim.bo[event.buf].fileformat = 'dos'
    end,
  })

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true

  -- [[ Basic Keymaps ]]
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = true,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = false, -- Text shows up at the end of the line
    virtual_lines = true, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- TIP: Disable arrow keys in normal mode
  -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Keep the visual selection after indenting/outdenting, so `<`/`>` can be
  -- pressed repeatedly without having to reselect with `gv` each time.
  vim.keymap.set('v', '<', '<gv', { desc = 'Decrease indent (keep selection)' })
  vim.keymap.set('v', '>', '>gv', { desc = 'Increase indent (keep selection)' })

  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
  -- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
  -- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
  -- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
  -- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })

  -- Most filetype plugins (c, cs, javascript, lua, ...) turn on 'formatoptions'
  -- flags that auto-continue the comment leader (e.g. `//`) onto the next
  -- line after <CR> in Insert mode ('r') or `o`/`O` in Normal mode ('o').
  -- Strip those; keep the rest of 'formatoptions' (e.g. `c`, which wraps
  -- long comment lines at 'textwidth') as each ftplugin sets it.
  vim.api.nvim_create_autocmd('FileType', {
    desc = "Don't auto-continue comment leader on new lines",
    group = vim.api.nvim_create_augroup('no-auto-comment-continuation', { clear = true }),
    pattern = '*',
    callback = function() vim.opt_local.formatoptions:remove { 'r', 'o' } end,
  })

  -- When the first non-blank character is typed on an otherwise-empty line,
  -- re-run the buffer's indentexpr to fix the leading whitespace (same as
  -- manually pressing <C-f> in insert mode — see 'indentkeys': the default
  -- "!^F" entry is exactly this). Catches cases where the indent computed on
  -- <CR>/o/O (e.g. from treesitter's indentexpr) doesn't match what the
  -- line's contents turn out to need.
  vim.api.nvim_create_autocmd('InsertCharPre', {
    desc = 'Fix indent when typing the first character on a blank line',
    group = vim.api.nvim_create_augroup('reindent-on-first-char', { clear = true }),
    callback = function()
      -- Skip whitespace itself (a manual Tab/Space shouldn't be fought) and
      -- skip when there's no indentexpr to recompute against.
      if vim.v.char:match '%s' or vim.bo.indentexpr == '' then return end
      if not vim.api.nvim_get_current_line():match '^%s*$' then return end

      -- InsertCharPre can't touch the buffer (textlock), so defer until the
      -- character has actually landed.
      vim.schedule(function()
        if vim.fn.mode() ~= 'i' then return end
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-f>', true, false, true), 'n', false)
      end)
    end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, todo-comments, mini modules
-- ============================================================
do
  -- [[ Installing and Configuring Plugins ]]
  --
  -- To install a plugin simply call `vim.pack.add` with its git url.
  -- This will download the default branch of the plugin, which will usually be `main` or `master`
  -- You can also have more advanced specs, which we will talk about later.
  --
  -- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
  --
  -- For example, lets say we want to install `guess-indent.nvim` - a plugin for
  -- automatically detecting and setting the indentation.
  --
  -- We first install it from https://github.com/NMAC427/guess-indent.nvim
  -- and then call its `setup()` function to start it with default settings.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Because lua is a real programming language, you can also have some logic to your installation -
  -- like only installing a plugin if a condition is met.
  --
  -- Here we only install `nvim-web-devicons` (which adds pretty icons) if we have a Nerd Font,
  -- since otherwise the icons won't display properly.
  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  -- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
  --
  -- See `:help gitsigns` to understand what each configuration key does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- Useful plugin to show you pending keybinds.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- `<auto>` covers every other trigger via which-key's normal detection;
    -- `L` is added explicitly because which-key's auto-trigger scan refuses
    -- to shadow bare single-key builtins other than g/z/Z, and `L` (cursor
    -- to last line) doesn't qualify. Only activates where real `L*`
    -- keymaps exist (i.e. once an LSP attaches), so it's a no-op elsewhere.
    triggers = {
      { '<auto>', mode = 'nxso' },
      { 'L', mode = { 'n', 'x' } },
    },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      -- Bare `L` (no leader) rather than `<leader>l`: every submap below is
      -- buffer-local, only set once an LSP client attaches, so this only
      -- shadows the builtin `L` motion in buffers you're actively coding in.
      { 'L', group = '[L]SP Actions', mode = { 'n', 'x' } },
    },
  }

  -- [[ Colorscheme ]]
  -- Moved to `lua/custom/plugins/colortheme.lua` (loaded at the end of this
  -- file via `require 'custom.plugins'`).

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

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
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy Finder (files, lsp, etc) ]]
  --
  -- Telescope is a fuzzy finder that comes with a lot of different things that
  -- it can fuzzy find! It's more than just a "file finder", it can search
  -- many different aspects of Neovim, your workspace, LSP, and more!
  --
  -- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
  -- so feel free to experiment and see what you like!
  --
  -- The easiest way to use Telescope, is to start by doing something like:
  --  :Telescope help_tags
  --
  -- After running this command, a window will open up and you're able to
  -- type in the prompt window. You'll see a list of `help_tags` options and
  -- a corresponding preview of the help.
  --
  -- Two important keymaps to use while in Telescope are:
  --  - Insert mode: <c-/>
  --  - Normal mode: ?
  --
  -- This opens a window that shows you all of the keymaps for the current
  -- Telescope picker. This is really useful to discover what Telescope can
  -- do as well as how to actually do it!

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  -- NOTE: You can install multiple plugins at once
  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    -- You can put your default mappings / updates / etc. in here
    --  All the info you're looking for is in `:help telescope.setup()`
    defaults = {
      -- Truncate long paths from the left so the filename (right side) always stays visible
      path_display = { 'truncate' },
      -- mappings = {
      --   i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      -- },
      mappings = {
        -- Insert-mode <C-d> used to be remapped to delete_buffer here, but
        -- that's a `defaults` mapping so it leaked into every picker (e.g.
        -- shadowing live_grep's preview-scroll-down while typing a query).
        -- Normal-mode 'dd' below is unaffected since it only makes sense
        -- in the buffers picker anyway.
        n = { ['dd'] = require('telescope.actions').delete_buffer },
      },
      layout_config = {
        width = 0.95,
        height = 0.95,
        -- preview_width only applies to layout strategies that actually have a
        -- separate preview pane sized this way (horizontal/cursor/bottom_pane).
        -- It must NOT sit at the flat/top level, or every picker inherits it —
        -- including ones on strategies that don't support the key (e.g. the
        -- `center` strategy used by telescope-ui-select's dropdown theme for
        -- LSP code actions), which errors out.
        horizontal = {
          -- Fixed 60/40 Preview/Results split instead of the default dynamic
          -- sizing (which only gives Preview ~40% on narrow windows).
          preview_width = 0.6,
        },
      },
    },
    pickers = {
      live_grep = {
        -- The Preview pane already shows the full matched line, so
        -- repeating it in Results just eats width there for nothing.
        show_line = false,
      },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  -- See `:help telescope.builtin`
  local builtin = require 'telescope.builtin'

  -- Custom entry_maker for LSP document/workspace symbol pickers: telescope's
  -- default (make_entry.gen_from_lsp_symbols) gives the type column
  -- `{ remaining = true }` (unbounded) width and hardcodes it to the full
  -- lowercase kind name (e.g. "method"), which is why it eats huge trailing
  -- padding. This collapses that column to one colored letter and never
  -- shows a path column for either picker (lsp_document_symbols already
  -- force-hides its path internally via opts.path_display = {'hidden'};
  -- lsp_dynamic_workspace_symbols does not, so this is what hides it there).
  local entry_display = require 'telescope.pickers.entry_display'
  local make_entry = require 'telescope.make_entry'

  -- Reuse telescope's own 8 TelescopeResults* group names (make_entry.lua's
  -- local lsp_type_highlight) so any existing overrides of those keep
  -- working, plus a few more kinds common in this repo's stack (C#, Lua,
  -- TS/Vue) that telescope doesn't cover.
  local symbol_kind_highlights = {
    Class = 'TelescopeResultsClass',
    Constant = 'TelescopeResultsConstant',
    Field = 'TelescopeResultsField',
    Function = 'TelescopeResultsFunction',
    Method = 'TelescopeResultsMethod',
    Property = 'TelescopeResultsOperator',
    Struct = 'TelescopeResultsStruct',
    Variable = 'TelescopeResultsVariable',
    Interface = 'TelescopeResultsInterface',
    Enum = 'TelescopeResultsEnum',
    EnumMember = 'TelescopeResultsEnumMember',
    Namespace = 'TelescopeResultsNamespace',
    Module = 'TelescopeResultsModule',
    Constructor = 'TelescopeResultsConstructor',
  }
  -- default = true: only applies if not already set, so these stay
  -- user/colorscheme-overridable and auto-match the active theme. LSP
  -- semantic tokens have no "module" or "constructor" type, so those two
  -- fall back to the closest standard type (namespace / method).
  vim.api.nvim_set_hl(0, 'TelescopeResultsInterface', { link = '@lsp.type.interface', default = true })
  vim.api.nvim_set_hl(0, 'TelescopeResultsEnum', { link = '@lsp.type.enum', default = true })
  vim.api.nvim_set_hl(0, 'TelescopeResultsEnumMember', { link = '@lsp.type.enumMember', default = true })
  vim.api.nvim_set_hl(0, 'TelescopeResultsNamespace', { link = '@lsp.type.namespace', default = true })
  vim.api.nvim_set_hl(0, 'TelescopeResultsModule', { link = '@lsp.type.namespace', default = true })
  vim.api.nvim_set_hl(0, 'TelescopeResultsConstructor', { link = '@lsp.type.method', default = true })

  local symbol_displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 1 },
      { remaining = true },
    },
  }

  -- Some servers (e.g. vue-language-server, typescript-language-server) bake
  -- a trailing ": ReturnType" / ": FieldType" straight into the symbol name.
  -- Drop it from the Results display (the preview pane already shows the
  -- real signature) by cutting at the first top-level ':' — i.e. the one
  -- not nested inside (), [], or {}, so parameter types like
  -- `doQuery(a: string): Promise<string>` still cut after the `)`.
  local function strip_return_type(name)
    local depth = 0
    for i = 1, #name do
      local c = name:sub(i, i)
      if c == '(' or c == '[' or c == '{' then
        depth = depth + 1
      elseif c == ')' or c == ']' or c == '}' then
        depth = depth - 1
      elseif c == ':' and depth == 0 then
        return name:sub(1, i - 1):gsub('%s+$', '')
      end
    end
    return name
  end

  local function lsp_symbol_display(entry)
    return symbol_displayer {
      { entry.symbol_type:sub(1, 1):upper(), symbol_kind_highlights[entry.symbol_type] },
      strip_return_type(entry.symbol_name),
    }
  end

  -- Mirrors telescope's own make_entry.gen_from_lsp_symbols, minus the path
  -- column, with the type column collapsed to one letter.
  local function lsp_symbol_entry_maker(entry)
    local symbol_type, symbol_name = entry.text:match '%[(.+)%]%s+(.*)'
    symbol_type = symbol_type or 'unknown'
    symbol_name = symbol_name or entry.text
    -- Filename isn't shown as a column, but keep it in `ordinal` so you can
    -- still fuzzy-filter a big workspace search (Lw) by file, e.g.
    -- to disambiguate same-named symbols across files.
    local ordinal_prefix = entry.filename and (vim.fn.fnamemodify(entry.filename, ':t') .. ' ') or ''
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = ordinal_prefix .. symbol_name .. ' ' .. symbol_type,
      display = lsp_symbol_display,
      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
      symbol_name = symbol_name,
      symbol_type = symbol_type,
      start = entry.start,
      finish = entry.finish,
    }, {})
  end

  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'Lr', builtin.lsp_references, { buffer = buf, desc = '[R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'Li', builtin.lsp_implementations, { buffer = buf, desc = '[I]mplementation' })

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'Ld', builtin.lsp_definitions, { buffer = buf, desc = '[D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      -- entry_maker: see lsp_symbol_entry_maker above — collapses the
      -- unbounded, hardcoded-lowercase type column down to one colored
      -- letter, and hides the path column (redundant for document_symbols,
      -- necessary for dynamic_workspace_symbols below).
      vim.keymap.set(
        'n',
        'Lo',
        function() builtin.lsp_document_symbols { entry_maker = lsp_symbol_entry_maker } end,
        { buffer = buf, desc = 'D[o]cument Symbols' }
      )

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set(
        'n',
        'Lw',
        function() builtin.lsp_dynamic_workspace_symbols { entry_maker = lsp_symbol_entry_maker } end,
        { buffer = buf, desc = '[W]orkspace Symbols' }
      )

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'Lt', builtin.lsp_type_definitions, { buffer = buf, desc = '[T]ype Definition' })
    end,
  })

  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- It's also possible to pass additional configuration options.
  --  See `:help telescope.builtin.live_grep()` for information about particular keys
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP Configuration ]]
  -- Brief aside: **What is LSP?**
  --
  -- LSP is an initialism you've probably heard, but might not understand what it is.
  --
  -- LSP stands for Language Server Protocol. It's a protocol that helps editors
  -- and language tooling communicate in a standardized fashion.
  --
  -- In general, you have a "server" which is some tool built to understand a particular
  -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
  -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
  -- processes that communicate with some "client" - in this case, Neovim!
  --
  -- LSP provides Neovim with features like:
  --  - Go to definition
  --  - Find references
  --  - Autocompletion
  --  - Symbol Search
  --  - and more!
  --
  -- Thus, Language Servers are external tools that must be installed separately from
  -- Neovim. This is where `mason` and related plugins come into play.
  --
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  -- Useful status updates for LSP.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  -- Always-on breadcrumb (winbar) showing the class/method the cursor is
  -- currently inside, driven by each LSP's document symbols.
  vim.pack.add { gh 'SmiteshP/nvim-navic' }
  require('nvim-navic').setup { separator = ' > ', highlight = true, depth_limit = 5 }
  vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"

  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('Ln', vim.lsp.buf.rename, 'Re[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('La', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('LD', vim.lsp.buf.declaration, '[D]eclaration')

      -- Restart the LSP client(s) attached to this buffer. Cheaper than
      -- quitting nvim entirely for cases like Roslyn caching stale
      -- .editorconfig-derived formatting options for a file that was
      -- created after the server was already running.
      -- Bare `:LspRestart` (no args) restarts *every* active client across
      -- all buffers, so scope it to just this buffer's client(s) by name.
      map('LR', function()
        local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients { bufnr = 0 })
        if #names == 0 then return end
        vim.cmd('LspRestart ' .. table.concat(names, ' '))
      end, '[R]estart')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('Lh', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, 'Toggle Inlay [H]ints')
      end

      -- Feed the winbar breadcrumb (nvim-navic) from this client's document symbols.
      if client and client:supports_method('textDocument/documentSymbol', event.buf) then require('nvim-navic').attach(client, event.buf) end

      -- Prefer the LSP's own folding ranges over treesitter's syntax-only folds
      -- when the attached client supports them.
      if client and client:supports_method('textDocument/foldingRange') then
        vim.wo[vim.api.nvim_get_current_win()][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
      end
    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    -- ts_ls = {},

    stylua = {}, -- Used to format Lua code

    ts_ls = {
      init_options = {
        plugins = {
          {
            name = '@vue/typescript-plugin',
            location = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'vue-language-server', 'node_modules', '@vue', 'typescript-plugin'),
            languages = { 'vue' },
          },
        },
      },
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    },

    vue_ls = {},

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  -- 官方 mason-registry 沒有真正的 Roslyn LSP 套件（只有不同專案的
  -- csharp-language-server），實際能用的 `roslyn` 套件只在 Crashdummyy
  -- 的自訂 registry 裡，執行檔會裝成 `roslyn.cmd`。
  require('mason').setup {
    registries = {
      'github:Crashdummyy/mason-registry',
      'github:mason-org/mason-registry',
    },
  }

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  -- Some lspconfig names differ from their mason package names, so filter them out
  -- and add the correct mason package names explicitly below
  local lspconfig_to_mason = { vue_ls = 'vue-language-server', ts_ls = 'typescript-language-server' }
  local ensure_installed = vim.tbl_filter(function(n) return not lspconfig_to_mason[n] end, vim.tbl_keys(servers or {}))
  vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
    -- csharpier removed: not used for cs formatting anymore (see conform's
    -- formatters_by_ft — Roslyn LSP formatting is used instead), and Mason's
    -- self-contained build crashes on startup on this machine anyway.
    'prettier',
    'vue-language-server',
    'typescript-language-server',
    'roslyn',
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }

  -- Filetypes to autoformat on save and on leaving Insert mode:
  local enabled_filetypes = {
    cs = true,
    -- lua = true,
    -- python = true,
    javascript = true,
    typescript = true,
    vue = true,
    css = true,
    json = true,
    html = true,
  }

  require('conform').setup {
    notify_on_error = true,
    format_on_save = function(bufnr)
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      -- cs: intentionally no external formatter. CSharpier is a fixed-opinion
      -- formatter (like Prettier/gofmt) that ignores this project's
      -- .editorconfig codeStyle rules (brace placement, expression-bodied
      -- preferences, spacing, etc.) entirely, so its output doesn't match
      -- Visual Studio's "Format Document". Falling through to
      -- `lsp_format = 'fallback'` below routes formatting through Roslyn's
      -- own textDocument/formatting instead, which is the same formatting
      -- engine VS uses and does honor .editorconfig.
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
      javascript = { 'prettier' },
      typescript = { 'prettier' },
      vue = { 'prettier' },
      css = { 'prettier' },
      json = { 'prettier' },
      html = { 'prettier' },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

  -- Also save when leaving Insert mode (for filetypes enabled above), which
  -- triggers `format_on_save` above rather than formatting directly here.
  local format_on_insert_leave_group = vim.api.nvim_create_augroup('kickstart-format-on-insert-leave', { clear = true })
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = format_on_insert_leave_group,
    callback = function(event)
      if enabled_filetypes[vim.bo[event.buf].filetype] and vim.bo[event.buf].buftype == '' and vim.fn.bufname(event.buf) ~= '' then
        vim.cmd 'update'
      end
    end,
  })
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets
  --
  vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'default',

      -- Custom overrides on top of the 'default' preset above.
      -- <Tab> tries accept first; if no completion menu is open (e.g. mid
      -- snippet from Roslyn's `prop`/`ctor`/... templates), it falls through
      -- to jumping to the next snippet tabstop, then to normal <Tab> input.
      ['<Tab>'] = {
        'select_and_accept',
        -- If blink had nothing to accept, fall back to accepting Roslyn's
        -- inline_completion ghost text (same source <M-i> in dotnet.lua uses).
        function()
          if vim.lsp.inline_completion.get() then return true end
        end,
        'snippet_forward',
        'fallback',
      },
      ['<M-j>'] = { 'select_next', 'fallback' },
      ['<M-k>'] = { 'select_prev', 'fallback' },

      -- <C-space> is blink's default manual-show key, but Windows intercepts
      -- Ctrl+Space as an IME toggle before it ever reaches the terminal/nvim.
      -- <C-.> is unclaimed anywhere else in this config and isn't an OS shortcut.
      ['<C-b>'] = { 'show', 'show_documentation', 'hide_documentation' },
      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },

      -- Add a border around the completion menu popup.
      menu = { border = 'rounded' },

      list = {
        selection = {
          -- Don't insert the selected item's text into the buffer just from
          -- moving the selection; only ghost_text previews it, and accepting
          -- (<Tab>) still inserts for real.
          auto_insert = false,
        },
      },

      -- Disabled: overlapped visually with Roslyn's own inline_completion
      -- ghost text (both render inline right after the cursor), and carried
      -- less information than the whole-line/whole-method suggestions
      -- Roslyn shows there.
      ghost_text = { enabled = false },

      trigger = {
        -- Auto-pop on every keyword character while typing, not just on LSP
        -- trigger characters. NOTE: this can visually collide with Roslyn's
        -- inline_completion ghost text, which was the original reason this
        -- was turned off — revisit if it becomes annoying again.
        show_on_keyword = true,
      },
    },

    sources = {
      default = { 'lsp', 'snippets', 'buffer' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    --
    -- use_proximity (on by default) boosts candidates whose text also shows
    -- up as a "nearby word" within ~30 lines of the cursor. In files full of
    -- near-identical boilerplate (e.g. a block of GetListData/Request/
    -- Result/Status methods), that swamps a clean prefix match (e.g. typing
    -- "is" for "IsAdd") with matches that merely contain "is" mid-word but
    -- share vocabulary with the surrounding lines. Turn it off so ranking is
    -- driven by match quality (prefix/word-boundary), not local word density.
    fuzzy = {
      implementation = 'prefer_rust_with_warning',
      use_proximity = false,
      -- 0 typos tolerated (matches fzf's default) — the default scales with
      -- keyword length and lets loosely-related identifiers (any string
      -- containing the query letters *somewhere*, out of camelCase-hump
      -- order) sneak into the menu as noise alongside the real match.
      max_typos = 0,
      -- Put exact/higher-quality matches first so the best candidate isn't
      -- buried under noisier subsequence matches (frizbee has no
      -- camelCase-hump-only filter, so noise can't be fully eliminated,
      -- only outranked).
      sorts = { 'exact', 'score', 'sort_text' },
    },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers = { 'bash', 'c', 'c_sharp', 'css', 'diff', 'html', 'javascript', 'jsdoc', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'typescript', 'vim', 'vimdoc', 'vue' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })

  -- [[ Sticky context ]]
  --  Pins the enclosing function/class signature to the top of the window
  --  when it scrolls out of view, so you always know which member the
  --  cursor is currently inside.
  vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-context' }
  require('treesitter-context').setup { max_lines = 3 }
end

-- ============================================================
-- SECTION 9: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  require 'kickstart.plugins.debug'
  -- require 'kickstart.plugins.indent_line'
  -- require 'kickstart.plugins.lint'
  require 'kickstart.plugins.autopairs'
  require 'kickstart.plugins.neo-tree'
  -- require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  -- NOTE: You can add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  require 'custom.plugins'
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

-- 賀的配置
do
  -- 在 insert mode 快速連按 j + j 離開
  vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode' })

  -- smear-cursor
  vim.pack.add {
    'https://github.com/sphamba/smear-cursor.nvim',
  }

  require('smear_cursor').setup {
    stiffness = 0.8,
    trailing_stiffness = 0.5,
    distance_stop_animating = 0.5,
    smear_insert_mode = false,
  }
end
