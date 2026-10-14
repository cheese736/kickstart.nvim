-- [[ Folding (nvim-ufo) ]]
-- ufo computes folds itself (it switches windows to foldmethod=manual) and
-- renders closed folds with their highlighted first line instead of the
-- plain foldtext. See https://github.com/kevinhwang91/nvim-ufo

vim.pack.add {
  'https://github.com/kevinhwang91/promise-async',
  'https://github.com/kevinhwang91/nvim-ufo',
}

-- ufo needs a high foldlevel: a low one would auto-close folds whenever the
-- fold ranges get recomputed.
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99 -- start with every fold open
vim.o.foldenable = true

-- 1-wide gutter column with open/closed icons (clickable). `foldinner`
-- hides the numeric nesting level a narrow foldcolumn would otherwise show.
-- Icons are Nerd Font codicons chevron-down / chevron-right.
vim.o.foldcolumn = '1'
vim.opt.fillchars:append { fold = ' ', foldopen = '\u{eab4}', foldclose = '\u{eab6}', foldsep = ' ', foldinner = ' ' }

-- Provider chain lsp -> treesitter -> indent (from ufo's doc/example.lua):
-- keeps the old behavior of preferring the LSP's semantic folding ranges
-- (e.g. Roslyn for C#) and using treesitter where no attached client
-- provides them, with indent as the last resort.
---@param bufnr integer
local function lsp_treesitter_indent(bufnr)
  local function fallback(err, provider)
    if type(err) == 'string' and err:match 'UfoFallbackException' then
      return require('ufo').getFolds(bufnr, provider)
    else
      return require('promise').reject(err)
    end
  end

  return require('ufo')
    .getFolds(bufnr, 'lsp')
    :catch(function(err) return fallback(err, 'treesitter') end)
    :catch(function(err) return fallback(err, 'indent') end)
end

-- Show the number of hidden lines (e.g. ` 󰁂 12`) after a closed fold's
-- first line instead of the default ellipsis.
local function fold_virt_text(virt_text, lnum, end_lnum, width, truncate)
  local new_virt_text = {}
  local suffix = (' 󰁂 %d '):format(end_lnum - lnum)
  local suf_width = vim.fn.strdisplaywidth(suffix)
  local target_width = width - suf_width
  local cur_width = 0
  for _, chunk in ipairs(virt_text) do
    local chunk_text = chunk[1]
    local chunk_width = vim.fn.strdisplaywidth(chunk_text)
    if target_width > cur_width + chunk_width then
      table.insert(new_virt_text, chunk)
    else
      chunk_text = truncate(chunk_text, target_width - cur_width)
      table.insert(new_virt_text, { chunk_text, chunk[2] })
      chunk_width = vim.fn.strdisplaywidth(chunk_text)
      -- truncate() may return a narrower string than asked for; pad it.
      if cur_width + chunk_width < target_width then suffix = suffix .. (' '):rep(target_width - cur_width - chunk_width) end
      break
    end
    cur_width = cur_width + chunk_width
  end
  table.insert(new_virt_text, { suffix, 'MoreMsg' })
  return new_virt_text
end

require('ufo').setup {
  provider_selector = function() return lsp_treesitter_indent end,
  fold_virt_text_handler = fold_virt_text,
}

-- ufo requires these: the builtin zR/zM change 'foldlevel', which ufo needs
-- to stay high.
vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })

-- On a closed fold, K previews the hidden lines in a float; elsewhere it
-- does LSP hover (or 'keywordprg' when no client can hover). Mapped
-- globally on purpose: Nvim only sets its own buffer-local LSP `K` when no
-- `K` mapping exists, so this one wins in every buffer.
vim.keymap.set('n', 'K', function()
  if require('ufo').peekFoldedLinesUnderCursor() then return end
  if #vim.lsp.get_clients { bufnr = 0, method = 'textDocument/hover' } > 0 then
    vim.lsp.buf.hover()
  else
    vim.cmd 'normal! K'
  end
end, { desc = 'Peek fold / Hover' })
