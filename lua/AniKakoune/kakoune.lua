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

local get_character_type_by_key = function(char_type)
  if char_type == CharacterType.WhiteSpace then
    return "white_space"
  elseif char_type == CharacterType.Word then
    return "word"
  elseif char_type == CharacterType.Punctuation then
    return "punctuation"
  elseif char_type == CharacterType.EndOfLine then
    return "end_of_line"
  else
    return "unknown"
  end
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
  local current_pos = {vim.fn.line('.'), vim.fn.col('.')}
  local hl_start = {current_pos[1], current_pos[2]}
  local hl_end = {current_pos[1], current_pos[2]}
  -- print(get_character_type_by_key(get_character_type(get_next_char(current_pos, line_content))))

  if target == M.Targets.NextWordStart then
    for i = 1, count do
      -- while true
      local moved_from_original = false
      while true do
        -- print("evaluating for pos", vim.inspect(current_pos), vim.inspect(line_content))
        local current_char = get_current_char(current_pos, line_content)
        local current_type = get_character_type(current_char)

        local next_char = get_next_char(current_pos, line_content)
        local next_type = get_character_type(next_char)
        local moved_new_line = false
        print("evaluating:", current_char, current_type, next_char, next_type)
        if hl_start[2] ~= current_pos[2] then
          if current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace then
            hl_end = {current_pos[1], current_pos[2]}
            break
          end
          if current_type == CharacterType.Punctuation and next_type == CharacterType.Word then
            hl_end = {current_pos[1], current_pos[2]}
            break
          end
          if current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation then
            hl_end = {current_pos[1], current_pos[2]}
            break
          end
          if next_type == CharacterType.EndOfLine then
            hl_end = {current_pos[1], current_pos[2]}
            break
          end
        else -- start == current
          if moved_from_original == true then
            if current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation then
              hl_end = {current_pos[1], current_pos[2]}
              break
            end
            if current_type == CharacterType.Punctuation and next_type == CharacterType.Word then
              hl_end = {current_pos[1], current_pos[2]}
              break
            end
            if next_type == CharacterType.EndOfLine then
              hl_end = {current_pos[1], current_pos[2]}
              break
            end
          else
            if get_character_type(current_char) == CharacterType.EndOfLine or get_character_type(next_char) == CharacterType.EndOfLine then
              current_pos[1] = current_pos[1] + 1
              current_pos[2] = 1
              hl_start = {current_pos[1], current_pos[2]}
              hl_end = {current_pos[1], current_pos[2]}
              line = current_pos[1]
              line_content = vim.fn.getline(line)
              moved_new_line = true
            else
              if current_type == CharacterType.Punctuation and next_type ~= CharacterType.WhiteSpace then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
              if current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
              if current_type == CharacterType.WhiteSpace and next_type == CharacterType.Word then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
            end
          end
          -- if next_type ~= CharacterType.Word and next_type ~= CharacterType.WhiteSpace and next_type ~= CharacterType.EndOfLine then
          --   word_start[2] = word_start[2] + 1
          -- end
        end -- end else start == curent

        if not moved_new_line then
          current_pos[2] = current_pos[2] + 1
          if current_pos[2] > #line_content then
            break
          end
        end
      end
      -- print("word_start", vim.inspect(word_start), "word_end", vim.inspect(word_end))
    end
  end
  return { hl_start, hl_end }
end
return M
