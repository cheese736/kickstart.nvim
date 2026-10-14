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
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
}
if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, 'https://github.com/nvim-telescope/telescope-fzf-native.nvim') end

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
    buffers = {
      -- Start in normal mode: j/k to move, dd to close a buffer, i to filter.
      initial_mode = 'normal',
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
  -- still fuzzy-filter a big workspace search (LW) by file, e.g.
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
    vim.keymap.set('n', 'LR', builtin.lsp_references, { buffer = buf, desc = '[R]eferences' })

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    vim.keymap.set('n', 'LI', builtin.lsp_implementations, { buffer = buf, desc = '[I]mplementation' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    -- To jump back, press <C-t>.
    vim.keymap.set('n', 'LD', builtin.lsp_definitions, { buffer = buf, desc = '[D]efinition' })

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    -- entry_maker: see lsp_symbol_entry_maker above — collapses the
    -- unbounded, hardcoded-lowercase type column down to one colored
    -- letter, and hides the path column (redundant for document_symbols,
    -- necessary for dynamic_workspace_symbols below).
    vim.keymap.set(
      'n',
      'LO',
      function() builtin.lsp_document_symbols { entry_maker = lsp_symbol_entry_maker } end,
      { buffer = buf, desc = 'D[o]cument Symbols' }
    )

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    vim.keymap.set(
      'n',
      'LW',
      function() builtin.lsp_dynamic_workspace_symbols { entry_maker = lsp_symbol_entry_maker } end,
      { buffer = buf, desc = '[W]orkspace Symbols' }
    )

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    vim.keymap.set('n', 'LT', builtin.lsp_type_definitions, { buffer = buf, desc = '[T]ype Definition' })
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
