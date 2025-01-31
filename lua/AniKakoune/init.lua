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
    -- print(vim.inspect(start_pos), vim.inspect(end_pos))
    current_mark = vim.api.nvim_buf_set_extmark(0, ns_id, start_pos[1] -1, start_pos[2] -1, {
      end_row = end_pos[1] -1,
      end_col = end_pos[2],
      hl_group = 'Visual'
    })
  end
end

M.setup = function(config)
  local opts = config or {}
  local mode = opts.mode or "kakoune"
  local word = opts.word_keys or { "w", "b", "e", "W", "B", "E" }
  local edit = opts.edit_keys or {
    "c", "d", "s", "r"
  }

  for _, k in ipairs(word) do
    vim.keymap.set({ 'n' }, k, function()
      -- Store starting position before movement
      start_pos = { vim.fn.line('.'), vim.fn.col('.') }
      vim.cmd("normal! " .. (vim.v.count > 0 and (vim.v.count .. k) or k))
      -- if k == "w" or k == "W" then
      --   vim.cmd("normal! h")
      -- end
      vim.schedule(function()
        if k == "b" or k == "B" then
          end_pos = { vim.fn.line('.'), vim.fn.col('.') }
          start_pos, end_pos = end_pos, start_pos
        else
          end_pos = { vim.fn.line('.'), vim.fn.col('.') }
        end
        kakActive = true
        highlight_selection()
      end)
    end)
  end

  for _, k in ipairs(edit) do
    vim.keymap.set({ 'n' }, k, function()
      if kakActive and start_pos and end_pos then
        vim.api.nvim_win_set_cursor(0, {start_pos[1], start_pos[2]-1})
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, {end_pos[1], end_pos[2] -1})
        vim.api.nvim_feedkeys(k, "n", true)
        kakActive = false
      else
        vim.api.nvim_feedkeys(k, "n", true)
      end
    end, { noremap = false })
  end

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = function(event)
      local from_mode = event.match:sub(1,1)
      -- local to_mode = event.match:sub(-1)

      if from_mode == 'n' then
        kakActive = false
        clear_highlight()
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
