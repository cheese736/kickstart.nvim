-- Embed the Claude Code CLI in a terminal split via the same MCP/WebSocket
-- protocol the official IDE integrations use: Claude can see the current
-- buffer, selection, and diagnostics, and proposed edits show up as diffs
-- right here instead of you having to paste code back and forth.
--
-- provider = 'native': no folke/snacks.nvim dependency, just a plain
-- terminal split (same style as the dotnet_term helper in dotnet.lua).
-- auto_start = false: don't spin up a background WebSocket server on every
-- nvim launch — only when <leader>ac (or another Claude command) is used.

vim.pack.add { 'https://github.com/coder/claudecode.nvim' }

require('claudecode').setup {
  auto_start = false,
  terminal = {
    provider = 'native',
    split_side = 'right',
    split_width_percentage = 0.30,
  },
}

require('which-key').add { { '<leader>a', group = '[A]I / Claude' } }

-- :ClaudeCode et al. only open the terminal — they don't start the
-- WebSocket/MCP server (that's gated behind auto_start, which we keep
-- false so nothing runs just from opening nvim). Without the server
-- running, `claude` gets no CLAUDE_CODE_SSE_PORT env var and falls back to
-- a plain, unintegrated chat session. So make sure it's up before any
-- command that opens/focuses a Claude session.
local function ensure_claude_server()
  local claudecode = require 'claudecode'
  if not claudecode.state.server then claudecode.start(false) end
end

vim.keymap.set('n', '<leader>ac', function()
  ensure_claude_server()
  vim.cmd 'ClaudeCode'
end, { desc = 'Claude: Toggle terminal' })
vim.keymap.set('n', '<leader>af', function()
  ensure_claude_server()
  vim.cmd 'ClaudeCodeFocus'
end, { desc = 'Claude: Focus/toggle' })
vim.keymap.set('n', '<leader>ar', function()
  ensure_claude_server()
  vim.cmd 'ClaudeCode --resume'
end, { desc = 'Claude: Resume session' })
vim.keymap.set('n', '<leader>aC', function()
  ensure_claude_server()
  vim.cmd 'ClaudeCode --continue'
end, { desc = 'Claude: Continue' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'Claude: Add current buffer' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Claude: Send selection' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'Claude: Accept diff' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'Claude: Deny diff' })
vim.keymap.set('n', '<leader>aS', '<cmd>ClaudeCodeStatus<cr>', { desc = 'Claude: Connection status' })

-- Double-tap <C-h> to jump out of the Claude terminal (which always sits on
-- the right, per split_side above) straight back into the editor window,
-- mirroring the <Esc><Esc> "exit terminal mode" mapping in init.lua but
-- folding in the window-left step too.
vim.keymap.set('t', '<C-h><C-h>', '<C-\\><C-n><C-w>h', { desc = 'Claude: Exit terminal & move to editor' })
