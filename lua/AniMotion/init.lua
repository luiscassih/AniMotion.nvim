local Utils = require('AniMotion.utils')
local M = {}
local ns_id = vim.api.nvim_create_namespace('AniMotion')
local current_mark = nil
local current_mark_buffer = nil
local isActive = false
local start_pos = nil
local end_pos = nil
local hl_group = "@AniMotion"

M.isActive = function()
  return isActive
end

local function clear_highlight()
  if current_mark and current_mark_buffer then
    vim.api.nvim_buf_del_extmark(current_mark_buffer, ns_id, current_mark)
    current_mark = nil
    current_mark_buffer = nil
  end
end

local function highlight_selection()
  clear_highlight()
  if start_pos and end_pos then
    if start_pos[1] > end_pos[1] then
      -- we pressed "b" at the beginning character of the line
      -- so we move the start position to the end col new current line
      start_pos = {end_pos[1], vim.fn.col('$')-1}
    else if start_pos[1] < end_pos[1] then
      -- we pressed "w" at the end of a word at the end of the line
      -- so we move the start position to the beginning of the line
      start_pos = {end_pos[1], 1}
      end
    end
    local hl_start = start_pos[2]
    local hl_end = end_pos[2]
    if hl_start > hl_end then
      hl_start, hl_end = hl_end, hl_start
    end
    if hl_end == 1 and hl_end == vim.fn.col('$') then
      current_mark = nil
      current_mark_buffer = nil
    else
      local current_buffer = vim.api.nvim_get_current_buf()
      current_mark = vim.api.nvim_buf_set_extmark(current_buffer, ns_id, start_pos[1] -1, hl_start -1, {
        end_row = end_pos[1] -1,
        end_col = hl_end,
        hl_group = hl_group,
      })
      current_mark_buffer = current_buffer
    end
  end
end

M.setup = function(config)
  local opts = config or {}
  local mode = opts.mode or "animotion"
  local word = opts.word_keys or {
    [Utils.Targets.NextWordStart] = "w",
    [Utils.Targets.NextWordEnd] = "e",
    [Utils.Targets.PrevWordStart] = "b",
    [Utils.Targets.NextLongWordStart] = "W",
    [Utils.Targets.NextLongWordEnd] = "E",
    [Utils.Targets.PrevLongWordStart] = "B",
  }
  local edit = opts.edit_keys or { "c", "d", "s", "r", "y" }
  local clear = opts.clear_keys or { "<Esc>" }
  local marks = opts.marks or {"y", "z"}
  local map_visual = opts.map_visual or true
  local hl_color = { bg = "#673AB7"}
  if opts.color then
    if opts.color == "Visual" then
      hl_group = "Visual"
    else
      if type(opts.color) == "table" then
        hl_color = opts.color
      else
        vim.notify("AniMotion: opts.color must be either 'Visual' or a table with highlight attributes", vim.log.levels.WARN)
      end
    end
  end
  vim.api.nvim_set_hl(0, "@AniMotion", hl_color)

  for target, k in ipairs(word) do
    vim.keymap.set({ 'n' }, k, function()
      if mode == "nvim" then
        start_pos = { vim.fn.line('.'), vim.fn.col('.') }
        vim.cmd("normal! " .. (vim.v.count > 0 and (vim.v.count .. k) or k))
        vim.schedule(function()
          end_pos = { vim.fn.line('.'), vim.fn.col('.') }
          isActive = true
          highlight_selection()
        end)
      else
        local mode_util
        if mode == "helix" then
          mode_util = require('AniMotion.helix')
        else
          mode_util = require('AniMotion.animotion')
        end
        local hl = mode_util.word_move(target, vim.v.count1)
        start_pos = hl[1]
        end_pos = hl[2]
        vim.fn.cursor(end_pos[1], end_pos[2])
        vim.schedule(function()
          isActive = true
          highlight_selection()
        end)
      end
    end)
  end

  for _, k in ipairs(edit) do
    vim.keymap.set({ 'n' }, k, function()
      if isActive and start_pos and end_pos then
        vim.api.nvim_buf_set_mark(0,marks[1], start_pos[1], start_pos[2]-1, {})
        vim.api.nvim_buf_set_mark(0,marks[2], end_pos[1], end_pos[2]-1, {})
        vim.api.nvim_feedkeys("`" .. marks[1] .. "v`" .. marks[2] .. k, "n", true)
        isActive = false
      else
        return k
      end
    end, { noremap = false, nowait = true, expr = true })
  end

  if map_visual then
    vim.keymap.set('n', 'v', function()
      if isActive then
        clear_highlight()
        if start_pos and end_pos then
          vim.api.nvim_buf_set_mark(0,'<', start_pos[1], start_pos[2]-1, {})
          vim.api.nvim_buf_set_mark(0,'>', start_pos[1], end_pos[2]-1, {})
          -- vim.cmd("normal! `<v`>")
          vim.api.nvim_feedkeys("`<v`>", "n", true)
          if start_pos[2] > end_pos[2] then
            vim.api.nvim_feedkeys("o", "n", true)
          end
        end
        isActive = false
      else
        return 'v'
      end
    end, { noremap = false, nowait = true, expr = true })
  end

  for _, k in ipairs(clear) do
    vim.keymap.set({ 'n' }, k, function()
      if isActive then
        clear_highlight()
        isActive = false
      else
        return k
      end
    end, { noremap = false, nowait = true, expr = true })
  end

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = function(event)
      local from_mode = event.match:sub(1,1)
      local to_mode = event.match:sub(-1)

      if isActive and (to_mode == 'v' or to_mode == 'V' or to_mode == '\22') then
        isActive = false
      else if from_mode == 'n' then
        isActive = false
        clear_highlight()
        end
      end
    end
  })

  vim.api.nvim_create_autocmd('CursorMoved', {
    pattern = '*',
    callback = function()
      clear_highlight()
      isActive = false
    end
  })
end

return M
