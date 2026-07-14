-- TFVC Pending Changes UI, modeled after Visual Studio Team Explorer's
-- Pending Changes pane: lists every pending change in the workspace,
-- lets you include/exclude files, then checks in the included ones
-- with a single comment.

local Popup = require 'nui.popup'
local tfvc = require 'custom.tfvc'

local M = {}

local state = {
  popup = nil,
  changes = {},
}

local function relative_path(path)
  local prefix = vim.pesc(tfvc.WORKSPACE_ROOT .. '\\')
  return (path:gsub('^' .. prefix, ''))
end

local function render()
  if not state.popup then
    return
  end
  local bufnr = state.popup.bufnr
  local lines = {}
  for _, change in ipairs(state.changes) do
    local box = change.included and '[x]' or '[ ]'
    table.insert(lines, string.format('%s %-2s %s', box, change.label, relative_path(change.local_path)))
  end
  if #lines == 0 then
    lines = { '(no pending changes)' }
  end
  vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
end

local function current_change()
  local row = vim.api.nvim_win_get_cursor(state.popup.winid)[1]
  return state.changes[row]
end

local function toggle_current()
  local change = current_change()
  if change then
    change.included = not change.included
    render()
  end
end

local function toggle_all()
  local any_excluded = false
  for _, c in ipairs(state.changes) do
    if not c.included then
      any_excluded = true
      break
    end
  end
  for _, c in ipairs(state.changes) do
    c.included = any_excluded
  end
  render()
end

local function refresh()
  tfvc.list_pending_changes(function(changes, err)
    if err then
      vim.notify(err, vim.log.levels.ERROR, { title = 'TFVC' })
      return
    end
    state.changes = changes
    render()
  end)
end

local function open_current_file()
  local change = current_change()
  if not change then
    return
  end
  state.popup:unmount()
  state.popup = nil
  vim.cmd('edit ' .. vim.fn.fnameescape(change.local_path))
end

local function close()
  if state.popup then
    state.popup:unmount()
    state.popup = nil
  end
end

local function do_checkin()
  local paths = {}
  for _, c in ipairs(state.changes) do
    if c.included then
      table.insert(paths, c.local_path)
    end
  end
  if #paths == 0 then
    vim.notify('No files selected', vim.log.levels.WARN, { title = 'TFVC' })
    return
  end
  vim.ui.input({ prompt = 'Checkin comment: ' }, function(comment)
    if comment == nil or vim.trim(comment) == '' then
      vim.notify('TFVC checkin cancelled', vim.log.levels.WARN, { title = 'TFVC' })
      return
    end
    tfvc.checkin_many(paths, comment, function(ok)
      if ok then
        close()
        vim.schedule(M.open)
      end
    end)
  end)
end

local function create_popup()
  local popup = Popup {
    enter = true,
    focusable = true,
    border = {
      style = 'rounded',
      text = { top = ' TFVC Pending Changes  (<Space> toggle  a all  <CR> open  c checkin  R refresh  q quit) ', top_align = 'center' },
    },
    position = '50%',
    size = { width = '80%', height = '70%' },
    buf_options = { modifiable = false },
  }
  popup:mount()

  local map_opts = { noremap = true, nowait = true }
  popup:map('n', '<Space>', toggle_current, map_opts)
  popup:map('n', '<Tab>', toggle_current, map_opts)
  popup:map('n', 'a', toggle_all, map_opts)
  popup:map('n', '<CR>', open_current_file, map_opts)
  popup:map('n', 'R', refresh, map_opts)
  popup:map('n', 'c', do_checkin, map_opts)
  popup:map('n', 'q', close, map_opts)
  popup:map('n', '<Esc>', close, map_opts)

  return popup
end

function M.open()
  if state.popup then
    vim.api.nvim_set_current_win(state.popup.winid)
    refresh()
    return
  end
  tfvc.list_pending_changes(function(changes, err)
    if err then
      vim.notify(err, vim.log.levels.ERROR, { title = 'TFVC' })
      return
    end
    if #changes == 0 then
      vim.notify('No pending changes', vim.log.levels.INFO, { title = 'TFVC' })
      return
    end
    state.changes = changes
    state.popup = create_popup()
    render()
  end)
end

return M
