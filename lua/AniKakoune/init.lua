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

-- local function get_word_bounds()
--     local cur_pos = vim.api.nvim_win_get_cursor(0)  -- 1-based row, 0-based col
--     local line = vim.api.nvim_get_current_line()
--     local col = cur_pos[2]

--     -- Adjust for 1-based column
--     col = col + 1
--     -- Get the text from current line
--     local result = vim.fn.matchstrpos(line, '\\k*\\%' .. col .. 'c\\k*')
--     -- result[2] is start col, result[3] is end col (0-based)

--     return {cur_pos[1], result[2] + 1}, {cur_pos[1], result[3]}
-- end

-- local function get_word_bounds()
--   local cur_pos = vim.api.nvim_win_get_cursor(0)  -- 1-based row, 0-based col
--   local line = vim.api.nvim_get_current_line()
--   local col = cur_pos[2]

--   -- Adjust for 1-based column
--   col = col + 1

--   -- Find word boundaries using vim's built-in word pattern
--   local before_cursor = line:sub(1, col - 1)
--   local after_cursor = line:sub(col)
  
--   -- Find the start of the word (looking backwards)
--   local start_offset = before_cursor:reverse():find("[^%w_]") or #before_cursor + 1
--   local start_col = math.max(1, #before_cursor - start_offset + 2)
  
--   -- Find the end of the word (looking forwards)
--   local end_offset = after_cursor:find("[^%w_]") or (#after_cursor + 1)
--   local end_col = col + end_offset - 2  -- Adjust to point to last word character
  
--   -- Check if cursor is on a word character
--   local char_at_cursor = line:sub(col, col)
--   if not char_at_cursor:match("[%w_]") then
--       return {cur_pos[1], col}, {cur_pos[1], col}
--   end

--   -- Check if there's a space after the word
--   local next_char = line:sub(end_col + 1, end_col + 1)
--   if next_char == " " then
--       end_col = end_col + 1
--   end

--   return {cur_pos[1], start_col}, {cur_pos[1], end_col}
-- end
--

-- Character categories
local CharCategory = {
  Whitespace = 1,
  Word = 2,
  Punctuation = 3,
  Unknown = 4
}

-- Categorize a character
local function categorize_char(char)
  if char:match('%s') then
    return CharCategory.Whitespace
  elseif char:match('[%w_]') then
    return CharCategory.Word
  else
    return CharCategory.Punctuation
  end
end

-- Check if we've hit a word boundary
local function is_word_boundary(prev_char, next_char)
  local prev_cat = categorize_char(prev_char)
  local next_cat = categorize_char(next_char)

  -- Different categories always form a boundary
  if prev_cat ~= next_cat then
    return true
  end

  -- Within word characters
  if prev_cat == CharCategory.Word then
    -- Underscore boundaries
    if (prev_char == '_') ~= (next_char == '_') then
      return true
    end
    -- Lowercase to uppercase transition (camelCase)
    if prev_char:match('[a-z]') and next_char:match('[A-Z]') then
      return true
    end
  end

  return false
end


local function get_word_bounds()
  local count = vim.v.count1

  -- Get current cursor position
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local last_line = vim.fn.line('$')

  for _ = 1, count do
    -- Get current line content
    local line = vim.fn.getline(cur_line)
    local line_length = #line

    -- Skip to next word start in current line
    while cur_col <= line_length do
      local prev_char = line:sub(cur_col, cur_col)
      local next_char = cur_col < line_length and line:sub(cur_col + 1, cur_col + 1) or '\n'

      -- Handle end of line
      if cur_col == line_length then
        if cur_line == last_line then
          return
        end
        -- Move to next line
        cur_line = cur_line + 1
        cur_col = 1
        line = vim.fn.getline(cur_line)
        line_length = #line
        break
      end

      -- Check for word boundary
      if is_word_boundary(prev_char, next_char) then
        -- Don't stop at whitespace boundaries
        if categorize_char(next_char) ~= CharCategory.Whitespace then
          cur_col = cur_col + 1
          break
        end
      end

      cur_col = cur_col + 1
    end

    -- Skip any whitespace
    line = vim.fn.getline(cur_line)
    while cur_col <= #line and line:sub(cur_col, cur_col):match('%s') do
      cur_col = cur_col + 1
    end
  end

  -- Move cursor to final position
  vim.fn.cursor(cur_line, cur_col)
end

M.setup = function(config)
  local opts = config or {}
  local mode = opts.mode or "word"
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
      else if mode == "kakoune" then
      else if mode == "word" then
        -- Store initial position
        -- First move to the next word
        -- Then get word boundaries at new position
        -- start_pos = vim.fn.searchpos('\\S\\+', 'bcn')
        -- end_pos = vim.fn.searchpos('\\S\\+', 'cen')
        -- print("start", vim.inspect(start_pos), "end", vim.inspect(end_pos))
        -- highlight_selection()

        -- start_pos, end_pos = get_word_bounds()
        -- print("start", vim.inspect(start_pos), "end", vim.inspect(end_pos))
        -- highlight_selection()
        --
        -- get_word_bounds()
        local Kakoune = require('AniKakoune.kakoune')
        local hl = Kakoune.word_move(Kakoune.Targets.NextWordStart, vim.v.count1)
        start_pos = hl[1]
        end_pos = hl[2]
        print("start", vim.inspect(start_pos), "end", vim.inspect(end_pos))
        vim.fn.cursor(end_pos[1], end_pos[2])
        vim.schedule(function()
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
