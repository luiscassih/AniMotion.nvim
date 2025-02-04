local M = {}
local ns_id = vim.api.nvim_create_namespace('AniKakoune')
local current_mark = nil
local kakActive = false
local start_pos = nil
local end_pos = nil

M.isKakouneMode = function()
  return kakActive
end

local function clear_highlight()
  if current_mark then
    vim.api.nvim_buf_del_extmark(0, ns_id, current_mark)
    current_mark = nil
  end
end

local function highlight_selection()
  clear_highlight()
  if start_pos and end_pos then
    -- print("to highlight start:", vim.inspect(start_pos), vim.inspect(end_pos))
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
    -- print("to highlight", vim.inspect(start_pos), vim.inspect(end_pos))
    if hl_end == 1 and hl_end == vim.fn.col('$') then
      current_mark = nil
    else
      current_mark = vim.api.nvim_buf_set_extmark(0, ns_id, start_pos[1] -1, hl_start -1, {
        end_row = end_pos[1] -1,
        end_col = hl_end,
        hl_group = 'Visual',
      })
    end
  end
end

M.setup = function(config)
  local opts = config or {}
  local mode = opts.mode or "kakoune"
  local word = opts.word_keys or { "w", "b", "e", "W", "B", "E" }
  local edit = opts.edit_keys or { "c", "d", "s", "r" }
  local marks = opts.marks or {"y", "z"}

  for _, k in ipairs(word) do
    vim.keymap.set({ 'n' }, k, function()
      if mode == "nvim" then
        start_pos = { vim.fn.line('.'), vim.fn.col('.') }
        vim.cmd("normal! " .. (vim.v.count > 0 and (vim.v.count .. k) or k))
        vim.schedule(function()
          end_pos = { vim.fn.line('.'), vim.fn.col('.') }
          kakActive = true
          highlight_selection()
        end)
      else if mode == "word" then
      else if mode == "kakoune" then
        local Kakoune = require('AniKakoune.kakoune')
        local target
        if k == "w" then
          target = Kakoune.Targets.NextWordStart
        elseif k == "W" then
          target = Kakoune.Targets.NextLongWordStart
        elseif k == "b" then
          target = Kakoune.Targets.PrevWordStart
        elseif k == "B" then
          target = Kakoune.Targets.PrevLongWordStart
        elseif k == "e" then
          target = Kakoune.Targets.NextWordEnd
        elseif k == "E" then
          target = Kakoune.Targets.NextLongWordEnd
        end
        local hl = Kakoune.word_move(target, vim.v.count1)
        start_pos = hl[1]
        end_pos = hl[2]
        -- print("start", vim.inspect(start_pos), "end", vim.inspect(end_pos))
        vim.fn.cursor(end_pos[1], end_pos[2])
        vim.schedule(function()
          kakActive = true
          highlight_selection()
        end)
      end
      end
      end
    end)
  end

  for _, k in ipairs(edit) do
    vim.keymap.set({ 'n' }, k, function()
      if kakActive and start_pos and end_pos then
        vim.api.nvim_buf_set_mark(0,marks[1], start_pos[1], start_pos[2]-1, {})
        vim.api.nvim_buf_set_mark(0,marks[2], end_pos[1], end_pos[2]-1, {})
        vim.cmd("normal! `" .. marks[1] .. "v`" .. marks[2])
        vim.api.nvim_feedkeys(k, "n", true)
        kakActive = false
      else
        vim.api.nvim_feedkeys(k, "n", true)
      end
    end, { noremap = false, nowait = true })
  end

  vim.keymap.set('n', 'v', function()
    if kakActive then
      clear_highlight()
      if start_pos and end_pos then
        vim.api.nvim_buf_set_mark(0,'<', start_pos[1], start_pos[2]-1, {})
        vim.api.nvim_buf_set_mark(0,'>', start_pos[1], end_pos[2]-1, {})
        vim.cmd("normal! `<v`>")
        if start_pos[2] > end_pos[2] then
          vim.api.nvim_feedkeys("o", "n", true)
        end
      end
      kakActive = false
    else
      vim.api.nvim_feedkeys("v", "n", true)
    end
  end, { noremap = false, nowait = true })

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = function(event)
      local from_mode = event.match:sub(1,1)
      local to_mode = event.match:sub(-1)

      if kakActive and (to_mode == 'v' or to_mode == 'V' or to_mode == '\22') then
        kakActive = false
      else if from_mode == 'n' then
        kakActive = false
        clear_highlight()
        end
      end
    end
  })

  vim.api.nvim_create_autocmd('CursorMoved', {
    pattern = '*',
    callback = function(event)
      if event.buf == vim.api.nvim_get_current_buf() then
        clear_highlight()
        kakActive = false
      end
    end
  })
end

return M
