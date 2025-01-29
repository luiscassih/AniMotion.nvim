local M = {}
local kakActive = false

M.isKakouneMode = function()
  return kakActive
end

M.setup = function(config)
  local opts = config or {}
  local word = opts.word_keys or { "w", "b", "e", "W", "B", "E" }
  local disableKak = opts.disable_keys or {
    "i", "a", "I", "A", "o", "O",
    "h", "j", "k", "l", "f", "F", "t", "T", "/", "?", "n", "N",
    "gg", "G", "$", "_", "0",
    "H", "L", "J", "K",
    "<C-d>", "<C-u>",
  }

  for _, k in ipairs(word) do
    vim.keymap.set({ 'n' }, k, function()
      if k == "w" then
        if vim.v.count > 1 then
          vim.cmd("normal! " .. vim.v.count-1 .. "wviw")
        else
          vim.cmd("normal! viw")
        end
        kakActive = true
        return
      end
      if k == "b" then
        if vim.v.count > 1 then
          vim.cmd("normal! " .. vim.v.count .. "bviwo")
        else
          vim.cmd("normal! viwo")
        end
        kakActive = true
        return
      end
      vim.cmd("normal! v" .. k)
      kakActive = true
    end)
    vim.keymap.set({ 'v' }, k, function()
      if (kakActive) then
        local count = vim.v.count1
        vim.cmd("normal! v")
        -- as we exited visual mode, we need to retrigger kak mode
        kakActive = true
        local original_pos = vim.fn.col('.')
        if k == "w" then
          vim.cmd("normal! " .. count .. "wviw")
          if vim.fn.col('.') == original_pos+1 and vim.fn.matchstr(vim.fn.getline('.'), '\\%' .. vim.fn.col('.') .. 'c[A-Za-z]') == '' then
            vim.cmd("normal! vwviw")
          end
          kakActive = true
          return
        end
        if k == "b" then
          vim.cmd("normal! " .. count .. "bviwo")
          if vim.fn.col('.') == original_pos-1 and vim.fn.matchstr(vim.fn.getline('.'), '\\%' .. vim.fn.col('.') .. 'c[A-Za-z]') == '' then
            vim.cmd("normal! vbviwo")
          end
          kakActive = true
          return
        end
        vim.cmd("normal! v" .. k)
      else
        if vim.v.count > 1 then
          vim.api.nvim_feedkeys(vim.v.count .. k, "n", true)
        else
          vim.api.nvim_feedkeys(k, "n", true)
        end
      end
    end)
  end

  -- Exit Kak mode and trigger default behavior
  for _, k in ipairs(disableKak) do
    vim.keymap.set('v', k, function()
      if kakActive then
        kakActive = false
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true) .. vim.v.count1 .. k, "n", true)
      else
        vim.cmd("normal! " .. vim.v.count1 .. k)
      end
    end, { nowait = true, expr = false })
  end
  vim.keymap.set('v', 'v', function()
    if kakActive then
      kakActive = false
    else
      vim.cmd("normal! v")
    end
  end, { nowait = true })

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = function(event)
      local from_mode = event.match:sub(1,1)
      -- local to_mode = event.match:sub(-1)

      if from_mode == 'v' or from_mode == 'V' or from_mode == '\22' then
        kakActive = false
      end
    end
  })
end

return M
