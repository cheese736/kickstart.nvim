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

  -- Code folding is handled by nvim-ufo, see lua/custom/plugins/ufo.lua.

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

  -- Disable macro recording (an accidental `q` starts "recording @x").
  --  Buffer-local `q` mappings (help, dapui floats, popups) still close their windows.
  vim.keymap.set('n', 'q', '<Nop>')

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  -- Only errors are shown anywhere (signs, underline, lines, float, jumps);
  -- warnings/hints are still collected, just hidden.
  local errors_only = { min = vim.diagnostic.severity.ERROR }
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many', severity = errors_only },
    underline = { severity = errors_only },
    signs = { severity = errors_only },

    -- Can switch between these as you prefer
    virtual_text = false, -- Text shows up at the end of the line
    virtual_lines = { current_line = true, severity = errors_only }, -- Virtual-line diagnostics, but only for the cursor's line (avoids layout jumping while typing)

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      severity = errors_only,
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', function() vim.diagnostic.setloclist { severity = errors_only } end, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Hide diagnostics while typing; show them again once back in Normal mode.
  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function() vim.diagnostic.enable(false) end,
  })
  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function() vim.diagnostic.enable(true) end,
  })

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- TIP: Disable arrow keys in normal mode
  vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

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

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, todo-comments, mini modules
-- ============================================================
require 'custom.plugins.guess-indent'
require 'custom.plugins.devicons'
require 'custom.plugins.gitsigns'
require 'custom.plugins.which-key'

-- [[ Colorscheme ]]
-- Moved to `lua/custom/plugins/colortheme.lua` (loaded at the end of this
-- file via `require 'custom.plugins'`).

require 'custom.plugins.todo-comments'
require 'custom.plugins.mini'

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
require 'custom.plugins.telescope'

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

  require 'custom.plugins.fidget'
  require 'custom.plugins.navic'

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
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('LN', vim.lsp.buf.rename, 'Re[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('LA', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })

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
        map('LH', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, 'Toggle Inlay [H]ints')
      end
    end,
  })

  require 'custom.plugins.lspconfig'
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
require 'custom.plugins.conform'

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
require 'custom.plugins.luasnip'
require 'custom.plugins.blink'

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  require 'custom.plugins.treesitter'
  require 'custom.plugins.treesitter-context'

  -- [[ Go to enclosing method start/end ]]
  --  The built-in `[m`/`]m` only track one level of brace nesting, so inside
  --  a namespace/class they land on the class's `{`/`}` instead of the
  --  current method's. Walk up the syntax tree to the nearest function/method
  --  node instead, falling back to the built-in motion where no parser is
  --  active.
  ---@param node TSNode
  local function is_function_node(node) return node:type():match 'function' or node:type():match 'method' end

  ---@param node TSNode
  local function enclosing_function_node()
    local node = vim.treesitter.get_node()
    while node do
      if is_function_node(node) then return node end
      node = node:parent()
    end
  end

  vim.keymap.set('n', '[m', function()
    local node = enclosing_function_node()
    if not node then return vim.cmd 'normal! [m' end
    local body = node:field('body')[1]
    local row, col = (body or node):start()
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
  end, { desc = 'Go to enclosing [m]ethod start' })

  vim.keymap.set('n', ']m', function()
    local node = enclosing_function_node()
    if not node then return vim.cmd 'normal! ]m' end
    local body = node:field('body')[1]
    local row, col = (body or node):end_()
    if col > 0 then col = col - 1 end -- end_() is exclusive; step back onto the closing brace
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
  end, { desc = 'Go to enclosing [m]ethod end' })
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
end
