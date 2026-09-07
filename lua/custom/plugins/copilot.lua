-- GitHub Copilot: cloud-backed ghost-text completion, alongside Roslyn's LSP
-- inline completion. Manually triggered (see keymap.next below) rather than
-- auto-popping on every pause, so suggestions only show up when asked for.
--
-- Disabled in favor of supermaven.lua. Left commented out (instead of
-- deleted) so switching back is a one-line uncomment.

--[[
vim.pack.add { 'https://github.com/zbirenbaum/copilot.lua' }

require('copilot').setup {
  suggestion = {
    enabled = false,
    auto_trigger = false,
    -- blink.cmp's menu is open almost continuously while typing an
    -- identifier (its default trigger fires on most keystrokes), so leaving
    -- this true effectively hid Copilot's ghost text all the time. The two
    -- don't actually visually conflict — blink's menu is a floating popup,
    -- Copilot's suggestion is inline virtual text after the cursor.
    hide_during_completion = false,
    keymap = {
      -- Copilot's own defaults are <M-l>/<M-]>/<M-[>/<C-]>; remapped to
      -- keys not otherwise claimed elsewhere in this config.
      accept = '<C-l>',
      accept_word = false,
      accept_line = false,
      -- With auto_trigger off, `next()` doubles as the manual trigger: it
      -- requests a suggestion if none is showing, and cycles to the next
      -- candidate if one already is.
      next = '<M-n>',
      prev = '<M-p>',
      dismiss = '<C-]>',
    },
  },
  panel = { enabled = false }, -- not using the separate suggestions-panel UI
}

-- Give Copilot's ghost text its own color, distinct from Roslyn's/blink.cmp's
-- default grey, so it's obvious at a glance which source a suggestion came from.
vim.api.nvim_set_hl(0, 'CopilotSuggestion', { fg = '#7aa2f7', italic = true })
--]]
