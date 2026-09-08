-- .NET development comfort layer: Roslyn LSP client, CodeLens, DAP attach,
-- and quick terminal shortcuts for the dotnet CLI.

vim.pack.add { 'https://github.com/seblyng/roslyn.nvim' }

-- broad_search: the TFVC workspace is a deep directory tree, so make sure the
-- .sln is found even when nvim is opened from a subdirectory of the solution.
-- filewatching = 'roslyn': tell the server we do NOT support dynamic
-- didChangeWatchedFiles registration, so the Roslyn server process falls
-- back to its own native file watcher instead of depending on Neovim's
-- client-side watcher + protocol negotiation to notice new .cs files.
require('roslyn').setup { broad_search = true, filewatching = 'roslyn' }

vim.lsp.config('roslyn', {
  -- roslyn.nvim's auto-discovery only looks for `roslyn-language-server(.cmd)`,
  -- but the mason package that actually ships a working server here
  -- (Crashdummyy registry's `roslyn`) installs its shim as `roslyn.cmd`.
  -- --logLevel / --extensionLogDirectory are required for this build: without
  -- them the server prints its usage text to stdout and corrupts the LSP framing.
  cmd = {
    vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin', 'roslyn.cmd'),
    '--logLevel=Information',
    '--extensionLogDirectory=' .. vim.fs.joinpath(vim.fn.stdpath 'log', 'roslyn'),
    '--stdio',
  },
  settings = {
    ['csharp|code_lens'] = {
      dotnet_enable_references_code_lens = true,
      dotnet_enable_tests_code_lens = true,
    },
    -- Turn off Roslyn's IDE/analyzer suggestions (CA*, IDE0090, IDE0028,
    -- "member can be marked as static", etc.) shown as diagnostic virtual
    -- text; real compiler errors/warnings (CS*) are a separate scope and
    -- keep working.
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'none',
    },
    -- Stop completion from suggesting types/extension methods from
    -- unimported namespaces and reference assemblies (e.g. transitive
    -- NuGet deps like Org.BouncyCastle). Without this, typing a short
    -- prefix like "is" floods the completion menu with unrelated
    -- third-party types that merely contain those letters.
    ['csharp|completion'] = {
      dotnet_show_completion_items_from_unimported_namespaces = false,
    },
    ['csharp|symbol_search'] = {
      dotnet_search_reference_assemblies = false,
    },
  },
})

-- Roslyn ships an LSP `textDocument/inlineCompletion` handler (used by VS's
-- IntelliCode whole-line/whole-method suggestions). Neovim 0.12+ has a native
-- client for this protocol (`vim.lsp.inline_completion`), so wire it up to
-- see whether this standalone Roslyn build actually returns anything —
-- IntelliCode's suggestion models normally ship with Visual Studio, so this
-- may just silently return no items.
vim.lsp.inline_completion.enable()

-- <M-i> accepts the ghost text; falls back to a literal <M-i> keypress
-- when nothing is showing. (Previously <C-j>, but that collides with
-- Ctrl-J-as-newline in insert mode.)
vim.keymap.set('i', '<M-i>', function()
  if not vim.lsp.inline_completion.get() then return '<M-i>' end
end, { expr = true, desc = 'Accept LSP inline completion (Roslyn IntelliCode)' })

-- Roslyn's `textDocument/_vs_onAutoInsert` (a non-standard LSP extension,
-- same protocol VS/VS Code's C# extension use) expands `///` into an XML
-- doc-comment skeleton: just <summary></summary> above a property, or a
-- full <summary>/<param>/<returns> skeleton above a method, matching the
-- member's actual signature. The server decides the content and the
-- tabstops entirely — we just forward every '/' keypress and let it
-- return nil for the (vast majority of) irrelevant cases, same as the
-- roslyn.nvim wiki recipe: https://github.com/seblyng/roslyn.nvim/wiki#textdocument_vs_onautoinsert
--
-- Deviates from that recipe by expanding via `luasnip.lsp_expand` instead
-- of `vim.snippet.expand`: blink.cmp's <Tab>/<S-Tab> (init.lua) only know
-- how to jump LuaSnip sessions (snippets.preset = 'luasnip'), not the
-- native vim.snippet engine, so using LuaSnip here lets the existing Tab
-- keymap jump between <summary>/<param>/<returns> for free.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('roslyn-doc-comment-auto-insert', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client.name == 'roslyn') then return end
    local bufnr = args.buf

    vim.api.nvim_create_autocmd('InsertCharPre', {
      desc = 'Roslyn: expand /// into an XML doc comment skeleton',
      buffer = bufnr,
      callback = function()
        if vim.v.char ~= '/' then return end

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        row, col = row - 1, col + 1
        local params = {
          _vs_textDocument = { uri = vim.uri_from_bufnr(bufnr) },
          _vs_position = { line = row, character = col },
          _vs_ch = '/',
          _vs_options = {
            tabSize = vim.bo[bufnr].tabstop,
            insertSpaces = vim.bo[bufnr].expandtab,
          },
        }

        -- Must fire after the '/' has actually landed in the buffer.
        vim.defer_fn(function()
          ---@diagnostic disable-next-line: param-type-mismatch
          client:request('textDocument/_vs_onAutoInsert', params, function(err, result)
            if err or not result then return end
            require('luasnip').lsp_expand(result._vs_textEdit.newText)
          end, bufnr)
        end, 1)
      end,
    })
  end,
})

-- Neither file-watching mode above is guaranteed to win a race against a
-- buffer that's created and saved for the very first time inside Neovim
-- itself. Belt-and-suspenders: track brand-new *.cs buffers (BufNewFile
-- fires when opening a path that doesn't exist on disk yet) and, the
-- moment that buffer is actually written for the first time
-- (BufWritePost), explicitly notify every attached roslyn client that the
-- file was Created — the same message the built-in watcher would have
-- sent, just pushed directly instead of depending on glob/registration
-- matching. Fires exactly once per new file.
local roslyn_new_file_group = vim.api.nvim_create_augroup('roslyn-new-file-notify', { clear = true })
local new_cs_buffers = {}

vim.api.nvim_create_autocmd('BufNewFile', {
  group = roslyn_new_file_group,
  pattern = '*.cs',
  callback = function(args) new_cs_buffers[args.buf] = true end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = roslyn_new_file_group,
  pattern = '*.cs',
  callback = function(args)
    local bufnr = args.buf
    if not new_cs_buffers[bufnr] then return end
    new_cs_buffers[bufnr] = nil -- one-shot: don't refire on later saves

    for _, client in ipairs(vim.lsp.get_clients { name = 'roslyn' }) do
      client:notify('workspace/didChangeWatchedFiles', {
        changes = { { uri = vim.uri_from_bufnr(bufnr), type = 1 } }, -- FileChangeType.Created
      })
    end
  end,
})

-- Drop the tracking entry if a new-file buffer is abandoned unsaved, so
-- the table doesn't accumulate stale entries.
vim.api.nvim_create_autocmd('BufDelete', {
  group = roslyn_new_file_group,
  pattern = '*.cs',
  callback = function(args) new_cs_buffers[args.buf] = nil end,
})

-- Enable CodeLens (e.g. "N references") for any LSP that supports it.
-- Nvim 0.12 refreshes codelens automatically on buffer changes internally,
-- so no manual refresh autocmd is needed (vim.lsp.codelens.refresh() is
-- deprecated in favor of vim.lsp.codelens.enable()).
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('custom-codelens', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not (client and client:supports_method 'textDocument/codeLens') then return end

    vim.lsp.codelens.enable(true, { bufnr = event.buf })
    vim.keymap.set('n', 'LC', vim.lsp.codelens.run, { buffer = event.buf, desc = '[C]odeLens' })
  end,
})

-- Attach to an already-running process (e.g. `dotnet watch run`), alongside
-- the existing launch config in kickstart.plugins.debug.
table.insert(require('dap').configurations.cs, {
  type = 'coreclr',
  name = 'attach - netcoredbg',
  request = 'attach',
  processId = require('dap.utils').pick_process,
})

-- Quick dotnet CLI terminal, reusing a single scratch split so repeated
-- commands don't stack up windows.
local dotnet_term = { win = nil }

local function dotnet_run(cmd)
  if dotnet_term.win and vim.api.nvim_win_is_valid(dotnet_term.win) then vim.api.nvim_win_close(dotnet_term.win, true) end
  vim.cmd 'botright new'
  vim.api.nvim_win_set_height(0, 15)
  vim.fn.jobstart(cmd, { term = true })
  vim.cmd.startinsert()
  dotnet_term.win = vim.api.nvim_get_current_win()
end

require('which-key').add { { '<leader>d', group = '[D]otnet' } }
vim.keymap.set('n', '<leader>db', function() dotnet_run 'dotnet build' end, { desc = 'Dotnet: [B]uild' })
vim.keymap.set('n', '<leader>dt', function() dotnet_run 'dotnet test' end, { desc = 'Dotnet: [T]est' })
vim.keymap.set('n', '<leader>dw', function() dotnet_run 'dotnet watch run' end, { desc = 'Dotnet: [W]atch run' })
vim.keymap.set('n', '<leader>dr', function() dotnet_run 'dotnet restore' end, { desc = 'Dotnet: [R]estore' })
