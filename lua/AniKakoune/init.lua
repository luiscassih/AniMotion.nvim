local M = {}
local kakActive = false

M.isKakouneMode = function()
  return kakActive
end

M.setup = function(config)
  local opts = config or {}
  local word = opts.word_keys or { "w", "b", "e", "W", "B", "E" }
  local disableKak = opts.disable_keys or {
    "i", "a", "I", "A",
    "h", "j", "k", "l", "f", "F", "t", "T", "/", "?", "n", "N",
    "gg", "G", "$", "_", "0",
    "H", "L", "J", "K",
    "<C-d>", "<C-u>",
  }

  for _, k in ipairs(word) do
    vim.keymap.set({ 'n' }, k, function()
      vim.cmd("normal! v" .. k)
      kakActive = true
    end)
    vim.keymap.set({ 'v' }, k, function()
      if (kakActive) then
        vim.cmd("normal! v")
        -- as we exited visual mode, we need to retrigger kak mode
        kakActive = true
        vim.cmd("normal! v" .. k)
      else
        vim.api.nvim_feedkeys(k, "n", true)
      end
    end)
  end

  -- Exit Kak mode and trigger default behavior
  for _, k in ipairs(disableKak) do
    vim.keymap.set('v', k, function()
      if (kakActive) then
        kakActive = false
        -- vim.api.nvim_input("<Esc>")
        -- vim.cmd("normal! v")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
      end
      vim.api.nvim_feedkeys(k, "n", true)
    end)
  end
  vim.keymap.set('v', 'v', function()
    if (kakActive) then
      kakActive = false
    else
      vim.api.nvim_feedkeys("v", "n", true)
    end
  end)

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
