-- [[ Autocomplete Engine ]]
vim.pack.add { { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' } }
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
    -- <Tab> order: accept the completion-menu selection first; if none, jump
    -- to the next snippet tabstop (so filling a Roslyn `///`/`prop`/`ctor`
    -- template isn't hijacked mid-snippet); if not in a snippet, accept
    -- Supermaven's inline ghost text; finally fall back to a literal <Tab>.
    ['<Tab>'] = {
      'select_and_accept',
      'snippet_forward',
      -- Accept Supermaven's inline ghost text, if it's showing one.
      -- (Supermaven's own accept key is <C-l>, kept as a backup; see supermaven.lua.)
      function()
        local supermaven = require 'supermaven-nvim.completion_preview'
        if supermaven.has_suggestion() then
          -- <Tab> is bound as an expr-mapping (blink.cmp/keymap/apply.lua),
          -- whose callback runs under textlock -- calling
          -- on_accept_suggestion() synchronously here throws E565 since it
          -- edits the buffer. Defer the actual edit past textlock.
          vim.schedule(function() supermaven.on_accept_suggestion() end)
          return true
        end
      end,
      'fallback',
    },
    ['<M-j>'] = { 'select_next', 'fallback' },
    ['<M-k>'] = { 'select_prev', 'fallback' },

    -- <C-space> is blink's default manual-show key, but Windows intercepts
    -- Ctrl+Space as an IME toggle before it ever reaches the terminal/nvim.
    -- <C-b> is unclaimed anywhere else in this config and isn't an OS shortcut.
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
