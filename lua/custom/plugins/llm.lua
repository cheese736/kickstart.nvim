-- llm.nvim: local ghost-text completion via Ollama (qwen2.5-coder:7b),
-- fully offline — added because Tabnine's local model can never download
-- on this network (config2.tabnine.com doesn't resolve, update.tabnine.com
-- 403s; confirmed a network-level block, not an nvim config problem).

vim.pack.add { 'https://github.com/huggingface/llm.nvim' }

require('llm').setup {
  -- llm.nvim's own llm-ls downloader can't run on Windows: it maps
  -- os_uname().sysname through a table keyed "Windows", but Windows
  -- actually reports "Windows_NT", so the lookup fails and it refuses to
  -- download anything ("Unsupported architecture or OS"). Mason's llm-ls
  -- build has proper win_x64 support, so install it via mason-tool-installer
  -- (see init.lua's `ensure_installed`) and point straight at that binary.
  lsp = {
    bin_path = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'llm-ls', 'llm-ls.exe'),
  },

  backend = 'ollama',
  model = 'qwen2.5-coder:7b',
  url = 'http://localhost:11434',

  -- Qwen2.5-Coder's FIM tokens use pipes (<|fim_prefix|>), different from
  -- llm.nvim's StarCoder-style default (<fim_prefix>, no pipes).
  fim = {
    enabled = true,
    prefix = '<|fim_prefix|>',
    middle = '<|fim_middle|>',
    suffix = '<|fim_suffix|>',
  },
  tokens_to_clear = { '<|endoftext|>', '<|im_end|>' },

  -- Default is 150ms, aggressive enough that a fast typist can fire a new
  -- getCompletions request before llm-ls finishes handling the previous
  -- one's $/cancelRequest. When that races, llm-ls occasionally writes
  -- malformed JSON to stdout (seen as "Parse error" / INVALID_SERVER_MESSAGE
  -- with id=null) — an upstream llm-ls bug, not fixable from here. Widening
  -- the debounce reduces how often the race window gets hit.
  debounce_ms = 500,

  request_body = {
    -- Required: llm-ls sends one combined prompt string (not Ollama's
    -- separate `suffix` field), so without raw=true Ollama applies this
    -- model's chat template and the FIM tokens get treated as chat text
    -- instead of triggering fill-in-middle. Verified via direct curl test.
    raw = true,
    options = { temperature = 0.2, top_p = 0.95, stop = { '<|endoftext|>', '<|im_end|>' } },
  },

  -- Default accept=<Tab>/dismiss=<S-Tab> collide with blink.cmp's own
  -- <Tab> (select_and_accept). <C-l>/<C-]> (Tabnine's keys) are also out:
  -- lua/custom/plugins/*.lua loads alphabetically, so tabnine.lua (loads
  -- after llm.lua) would silently re-bind those keys back to Tabnine,
  -- which currently returns nothing. <M-j>/<M-k> (blink nav) and <C-j>
  -- (Roslyn inline completion) are also taken. <M-l>/<M-]> are free.
  accept_keymap = '<M-l>',
  dismiss_keymap = '<M-]>',
}

-- llm.nvim links its suggestion highlight (`LLMSuggestion`) to `Comment` by
-- default, which makes it visually indistinguishable from Roslyn's inline
-- completion (vim.lsp.inline_completion) and blink.cmp's ghost_text preview
-- — all render as the same grey. Give it its own color so it's obvious at a
-- glance which ghost text came from the local Ollama model.
vim.api.nvim_set_hl(0, 'LLMSuggestion', { fg = '#bb9af7', italic = true })
