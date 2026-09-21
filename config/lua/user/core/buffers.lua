local M = {}
local api = vim.api

local function find_replacement_buffer(current_buf)
  local alternate = vim.fn.bufnr("#") -- Prefer the alternate buffer because it usually matches recent workflow.

  if
    alternate > 0
    and alternate ~= current_buf
    and api.nvim_buf_is_valid(alternate)
    and vim.bo[alternate].buflisted
  then
    return alternate
  end

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if
      buf ~= current_buf
      and api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
    then
      return buf -- Fall back to another listed buffer if no useful alternate buffer exists.
    end
  end

  return nil -- No existing listed buffer is available as a replacement.
end

-- Shared by keyboard and UI actions; no plugin owns buffer deletion.
function M.close(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local force_delete = false
  if vim.bo[bufnr].modified then
    local choice = vim.fn.confirm(
      "Save changes before closing this buffer?",
      "&Save\n&Discard\n&Cancel",
      3
    )

    if choice == 1 then
      local ok, err = pcall(api.nvim_buf_call, bufnr, function()
        vim.cmd.write() -- Write the target, even when a different buffer has focus.
      end)
      if not ok then
        vim.notify("Could not save buffer: " .. tostring(err), vim.log.levels.ERROR)
        return
      end
    elseif choice == 2 then
      force_delete = true
    else
      return
    end
  end

  local replaced_windows = {}
  local replacement
  local ok, err = pcall(function()
    for _, win in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(win) == bufnr then
        replacement = replacement or find_replacement_buffer(bufnr)
          or api.nvim_create_buf(true, false)
        api.nvim_win_set_buf(win, replacement)
        replaced_windows[#replaced_windows + 1] = win
      end
    end
    api.nvim_buf_delete(bufnr, { force = force_delete })
  end)

  if not ok then
    if api.nvim_buf_is_valid(bufnr) then
      for _, win in ipairs(replaced_windows) do
        if api.nvim_win_is_valid(win) then
          pcall(api.nvim_win_set_buf, win, bufnr)
        end
      end
    end
    vim.notify("Could not close buffer: " .. tostring(err), vim.log.levels.ERROR)
  end
end

return M
