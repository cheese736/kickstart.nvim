-- TFVC (Team Foundation Version Control) CLI wrapper
-- Used by lua/kickstart/plugins/neo-tree.lua to run tf.exe against the
-- node under the cursor in the neo-tree filesystem window.

local M = {}

local TF_EXE = 'D:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer\\TF.exe'
local SUBST_PREFIX = 'D:\\Substitute\\W\\'
local WORKSPACE_PREFIX = 'W:\\'

local COLLECTION = 'http://192.168.3.237:8080/teamnexgencollection'
local WORKSPACE = 'MIS_3420'
M.WORKSPACE_ROOT = 'W:\\Visual Studio 2022\\TeamNexgen.Surgery'

--- Convert a physical path (D:\Substitute\W\...) to the TFVC workspace path (W:\...).
function M.to_tf_path(path)
  local prefix = vim.pesc(SUBST_PREFIX)
  local converted = path:gsub('^' .. prefix, WORKSPACE_PREFIX)
  return converted
end

--- Run `tf <args>` asynchronously and notify with the result.
--- @param args string[]
--- @param on_exit fun(ok: boolean, stdout: string, stderr: string)|nil
function M.run(args, on_exit)
  local cmd = { TF_EXE }
  vim.list_extend(cmd, args)

  vim.system(cmd, { text = true }, function(result)
    local ok = result.code == 0
    vim.schedule(function()
      local out = (result.stdout or '') .. (result.stderr or '')
      out = vim.trim(out)
      vim.notify(out ~= '' and out or ('tf ' .. table.concat(args, ' ')), ok and vim.log.levels.INFO or vim.log.levels.ERROR, { title = 'TFVC' })
      if on_exit then
        on_exit(ok, result.stdout or '', result.stderr or '')
      end
    end)
  end)
end

--- Run `tf <args>` asynchronously without notifying (caller handles the result).
--- @param args string[]
--- @param on_exit fun(ok: boolean, stdout: string, stderr: string)
function M.run_raw(args, on_exit)
  local cmd = { TF_EXE }
  vim.list_extend(cmd, args)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      on_exit(result.code == 0, result.stdout or '', result.stderr or '')
    end)
  end)
end

local function chg_label(chg)
  local label = ''
  if chg:find 'Delete' then
    label = label .. 'D'
  end
  if chg:find 'Add' then
    label = label .. 'A'
  end
  if chg:find 'Rename' then
    label = label .. 'R'
  end
  if chg:find 'Edit' then
    label = label .. 'E'
  end
  if chg:find 'Encoding' and label == '' then
    label = label .. 'C'
  end
  return label ~= '' and label or '?'
end

--- List all pending changes in the TFVC workspace.
--- @param on_done fun(changes: table[]|nil, err: string|nil)
function M.list_pending_changes(on_done)
  local args = {
    'status',
    M.WORKSPACE_ROOT,
    '-recursive',
    '-format:xml',
    '-collection:' .. COLLECTION,
    '-workspace:' .. WORKSPACE,
  }
  M.run_raw(args, function(ok, out, err)
    if not ok then
      on_done(nil, vim.trim(err ~= '' and err or out))
      return
    end
    local changes = {}
    for line in out:gmatch '[^\r\n]+' do
      local attrs_str = line:match '<PendingChange%s+(.-)%s*/>'
      if attrs_str then
        local chg, local_path, item
        for key, value in attrs_str:gmatch '(%w+)="([^"]-)"' do
          if key == 'chg' then
            chg = value
          elseif key == 'local' then
            local_path = value
          elseif key == 'item' then
            item = value
          end
        end
        if local_path then
          table.insert(changes, {
            local_path = local_path,
            item = item,
            chg = chg or '',
            label = chg_label(chg or ''),
            included = true,
          })
        end
      end
    end
    on_done(changes, nil)
  end)
end

--- Checkin multiple files in one call.
--- @param paths string[]
--- @param comment string
--- @param on_done fun(ok: boolean, stdout: string, stderr: string)|nil
function M.checkin_many(paths, comment, on_done)
  local args = { 'checkin' }
  vim.list_extend(args, paths)
  vim.list_extend(args, { '-comment:' .. comment, '-noprompt', '-collection:' .. COLLECTION, '-workspace:' .. WORKSPACE })
  M.run(args, on_done)
end

local function with_recursive(args, node_type)
  if node_type == 'directory' then
    table.insert(args, '-recursive')
  end
  return args
end

function M.status(path, node_type, on_done)
  local tf_path = M.to_tf_path(path)
  M.run(with_recursive({ 'status', tf_path }, node_type), function(ok, out, err)
    if on_done then
      on_done(ok, out, err)
    end
  end)
end

function M.checkout(path, node_type, on_done)
  local tf_path = M.to_tf_path(path)
  M.run(with_recursive({ 'edit', tf_path }, node_type), on_done)
end

function M.checkin(path, node_type, on_done)
  local tf_path = M.to_tf_path(path)
  vim.ui.input({ prompt = 'Checkin comment: ' }, function(comment)
    if comment == nil or vim.trim(comment) == '' then
      vim.notify('TFVC checkin cancelled', vim.log.levels.WARN, { title = 'TFVC' })
      return
    end
    local args = with_recursive({ 'checkin', tf_path, '-comment:' .. comment, '-noprompt' }, node_type)
    M.run(args, on_done)
  end)
end

function M.undo(path, node_type, on_done)
  local tf_path = M.to_tf_path(path)
  local choice = vim.fn.confirm('Undo changes to ' .. path .. '?', '&Yes\n&No', 2)
  if choice ~= 1 then
    return
  end
  M.run(with_recursive({ 'undo', tf_path }, node_type), on_done)
end

function M.delete(path, node_type, on_done)
  local tf_path = M.to_tf_path(path)
  local choice = vim.fn.confirm('TFVC delete ' .. path .. '? This removes it from disk and pends a delete.', '&Yes\n&No', 2)
  if choice ~= 1 then
    return
  end
  M.run(with_recursive({ 'delete', tf_path }, node_type), on_done)
end

return M
