local M = {}

M.Targets = {
  NextWordStart = 1, -- w
  NextWordEnd = 2, -- e
  PrevWordStart = 3, -- b
  NextLongWordStart = 4, -- W
  NextLongWordEnd = 5, -- E
  PrevLongWordStart = 6, -- B
}

local CharacterType = {
  WhiteSpace = 1,
  Word = 2,
  Punctuation = 3,
  EndOfLine = 4,
  Unknown = 5
}

local get_character_type = function(char)
  if char == '\n' then
    return CharacterType.EndOfLine
  end
  if char:match('%s') then
    return CharacterType.WhiteSpace
  end
  if char:match('[%w_]') then
    return CharacterType.Word
  end
  if char:match('[^%s%w_]') then
    return CharacterType.Punctuation
  end
  return CharacterType.Unknown
end

local get_next_char = function(currentPos, line_content)
  return currentPos[2] < #line_content and line_content:sub(currentPos[2] + 1, currentPos[2] + 1) or '\n'
end

local get_current_char = function(currentPos, line_content)
  return line_content:sub(currentPos[2], currentPos[2])
end

local get_prev_char = function(currentPos, line_content)
  return currentPos[2] > 1 and line_content:sub(currentPos[2] - 1, currentPos[2] - 1) or '\n'
end

M.word_move = function(target, count)
  local line = vim.fn.line('.')
  local line_content = vim.fn.getline(line)
  local current_pos = {line, vim.fn.col('.')}
  local hl_start = {current_pos[1], current_pos[2]}
  local hl_end = {current_pos[1], current_pos[2]}
  for _ = 1, count do
    line = current_pos[1]
    line_content = vim.fn.getline(line)
    hl_start = {current_pos[1], current_pos[2]}
    hl_end = {current_pos[1], current_pos[2]}
    -- this original is the first time we hit a word movement
    local moved_from_original = false
    while true do
      -- print("evaluating for pos", vim.inspect(current_pos), vim.inspect(line_content))
      local current_char = get_current_char(current_pos, line_content)
      local current_type = get_character_type(current_char)

      local next_char = get_next_char(current_pos, line_content)
      local next_type = get_character_type(next_char)

      local prev_char = get_prev_char(current_pos, line_content)
      local prev_type = get_character_type(prev_char)

      -- print("evaluating:", current_char, current_type, next_char, next_type)
      if hl_start[2] ~= current_pos[2] then
        -- We already started highlighting the word, so we check if we are at the end of the word
        if next_type == CharacterType.EndOfLine then break end

        if target == M.Targets.NextWordStart then
          if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
            or (current_type == CharacterType.Punctuation and next_type == CharacterType.Word)
            or (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
          then
            break
          end
        end

        if target == M.Targets.NextLongWordStart then
          if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
          then
            break
          end
        end

        if target == M.Targets.NextWordEnd then
          if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
            or (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
            or (current_type == CharacterType.Punctuation and next_type ~= CharacterType.Punctuation)
          then
            break
          end
        end

        if target == M.Targets.NextLongWordEnd then
          if (current_type ~= CharacterType.WhiteSpace and next_type == CharacterType.WhiteSpace)
          then
            break
          end
        end
      else
        -- start == current, we start highlighting the word
        if moved_from_original == true then
          -- we already skipped the first character, for example, when we start at the space before a word
          -- so we don't need to keep skipping, for example, in " ((a"
          -- we start in space, we keep and moved_from_original is true, so we highlight all the non-word
          -- characters until we hit a word, so the result is "((" being highlighted
          if next_type == CharacterType.EndOfLine then break end
          if target == M.Targets.NextWordStart then
            if (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
              or (current_type == CharacterType.Punctuation and next_type == CharacterType.Word)
            then
              break
            end
          end

          -- NextLongWordStart doesn't need because punctuation and word are equal

          if target == M.Targets.NextWordEnd then
            if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
              or (current_type == CharacterType.Punctuation and next_type ~= CharacterType.Punctuation)
            then
              break
            end
          end

        else
          -- This is the first block to execute, we just started at the original, and didn't moved
          if current_type == CharacterType.EndOfLine
            or next_type == CharacterType.EndOfLine
          then
            -- To ignore empty lines
            current_pos[1] = current_pos[1] + 1
            current_pos[2] = 1
            hl_start = {current_pos[1], current_pos[2]}
            hl_end = {current_pos[1], current_pos[2]}
            line = current_pos[1]
            line_content = vim.fn.getline(line)
            goto continue
          end

          if target == M.Targets.NextWordStart then
            if (current_type == CharacterType.Punctuation and next_type ~= CharacterType.WhiteSpace)
              or (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
              or (current_type == CharacterType.WhiteSpace and next_type == CharacterType.Word)
            then
              hl_start[2] = hl_start[2] + 1
              moved_from_original = true
            end
          end

          if target == M.Targets.NextLongWordStart then
            if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
            then
              hl_start[2] = hl_start[2] + 1
              moved_from_original = true
            end
          end

          if target == M.Targets.NextWordEnd or target == M.Targets.NextLongWordEnd then
            if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
              or (current_type == CharacterType.Punctuation and next_type ~= CharacterType.Punctuation)
            then
              hl_start[2] = hl_start[2] + 1
              moved_from_original = true
            end
          end
        end
      end -- end else start == curent

      current_pos[2] = current_pos[2] + 1
      if current_pos[2] > #line_content then
        break
      end
    ::continue::
    end
  hl_end = {current_pos[1], current_pos[2]}
  end -- for
  return { hl_start, hl_end }
end
return M
