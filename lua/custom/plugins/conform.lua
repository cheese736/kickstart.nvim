-- [[ Formatting ]]
vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

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
    -- lua is not in `enabled_filetypes` above, so this only runs on demand
    -- via <leader>f (not format-on-save) — deliberate, so editing this config
    -- doesn't reformat+save on every InsertLeave.
    lua = { 'stylua' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    vue = { 'prettier' },
    css = { 'prettier' },
    json = { 'prettier' },
    html = { 'prettier' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- Paste and format: replay the paste (preserving any count/register the
-- user specified), then format just the pasted range for filetypes
-- enabled above.
local function paste_and_format(key, visual)
  return function()
    if visual then
      -- Lua-callback visual mappings drop out of Visual mode before the
      -- callback runs, so reselect the last visual area with `gv` first.
      vim.cmd.normal { args = { 'gv"' .. vim.v.register .. key }, bang = true }
    else
      local count = vim.v.count > 0 and tostring(vim.v.count) or ''
      vim.cmd.normal { args = { count .. '"' .. vim.v.register .. key }, bang = true }
    end

    if enabled_filetypes[vim.bo.filetype] and vim.bo.buftype == '' then
      require('conform').format {
        async = true,
        range = {
          start = vim.api.nvim_buf_get_mark(0, '['),
          ['end'] = vim.api.nvim_buf_get_mark(0, ']'),
        },
      }
    end
  end
end

vim.keymap.set('n', 'p', paste_and_format('p', false), { desc = 'Paste after and format' })
vim.keymap.set('n', 'P', paste_and_format('P', false), { desc = 'Paste before and format' })
vim.keymap.set('v', 'p', paste_and_format('p', true), { desc = 'Paste over selection and format' })

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
