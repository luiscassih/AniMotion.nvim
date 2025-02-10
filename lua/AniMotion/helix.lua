local Utils = require('AniMotion.utils')
local CharacterType = Utils.CharacterType
local M = {}

M.word_move = function(target, count)
  local is_prev = target == Utils.Targets.PrevWordStart or target == Utils.Targets.PrevLongWordStart
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
    if is_prev then
      while true do
        local current_char = Utils.get_current_char(current_pos, line_content)
        local current_type = Utils.get_character_type(current_char)

        local prev_char = Utils.get_prev_char(current_pos, line_content)
        local prev_type = Utils.get_character_type(prev_char)

        if hl_start[2] ~= current_pos[2] then
          if prev_type == CharacterType.EndOfLine then break end
          if target == Utils.Targets.PrevWordStart then
            if (current_type == CharacterType.Word and prev_type ~= CharacterType.Word)
              or (current_type == CharacterType.Punctuation and prev_type ~= CharacterType.Punctuation)
            then
              break
            end
          end

          if target == Utils.Targets.PrevLongWordStart then
            if (current_type == CharacterType.Word and prev_type == CharacterType.WhiteSpace)
              or (current_type == CharacterType.Punctuation and prev_type == CharacterType.WhiteSpace)
            then
              break
            end
          end
        else
          if current_type == CharacterType.EndOfLine
            or prev_type == CharacterType.EndOfLine
            or current_type == CharacterType.Unknown
          then
            if moved_from_original and current_type ~= CharacterType.Unknown then break end
            -- check if we are not at the beginning of the file
            if current_pos[1] == 1 then
              break
            end
            -- Keep jumping if line is empty
            current_pos[1] = current_pos[1] - 1
            line = current_pos[1]
            line_content = vim.fn.getline(line)
            current_pos[2] = #line_content
            hl_start = {current_pos[1], current_pos[2]}
            hl_end = {current_pos[1], current_pos[2]}
            moved_from_original = true
            goto continue
          end
          if moved_from_original == true then
            if prev_type == CharacterType.EndOfLine then break end

            if (current_type == CharacterType.Punctuation and prev_type ~= CharacterType.Punctuation)
              or (current_type == CharacterType.Word and prev_type ~= CharacterType.Word)
            then
              break
            end
          else
            if (current_type == CharacterType.Punctuation and prev_type ~= CharacterType.Punctuation)
              or (current_type == CharacterType.Word and prev_type ~= CharacterType.Word)
            then
              hl_start[2] = hl_start[2] - 1
              moved_from_original = true
            end
          end
        end

        current_pos[2] = current_pos[2] - 1
        if current_pos[2] <= 1 then
          break
        end

        ::continue::
      end
    else
      while true do
        local current_char = Utils.get_current_char(current_pos, line_content)
        local current_type = Utils.get_character_type(current_char)

        local next_char = Utils.get_next_char(current_pos, line_content)
        local next_type = Utils.get_character_type(next_char)

        if hl_start[2] ~= current_pos[2] then
          -- We already started highlighting the word, so we check if we are at the end of the word
          if next_type == CharacterType.EndOfLine then break end

          if target == Utils.Targets.NextWordStart then
            if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
              or (current_type == CharacterType.Punctuation and next_type == CharacterType.Word)
              or (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
            then
              break
            end
          end

          if target == Utils.Targets.NextLongWordStart then
            if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
            then
              break
            end
          end

          if target == Utils.Targets.NextWordEnd then
            if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
              or (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
              or (current_type == CharacterType.Punctuation and next_type ~= CharacterType.Punctuation)
            then
              break
            end
          end

          if target == Utils.Targets.NextLongWordEnd then
            if (current_type ~= CharacterType.WhiteSpace and next_type == CharacterType.WhiteSpace)
            then
              break
            end
          end
        else
          if current_type == CharacterType.EndOfLine
            or next_type == CharacterType.EndOfLine
            or current_type == CharacterType.Unknown
          then
            if moved_from_original and current_type ~= CharacterType.Unknown then break end
            -- check if we are not at the end of the file
            if current_pos[1] == vim.fn.line('$') then
              break
            end
            -- Keep jumping if line is empty
            current_pos[1] = current_pos[1] + 1
            current_pos[2] = 1
            hl_start = {current_pos[1], current_pos[2]}
            hl_end = {current_pos[1], current_pos[2]}
            line = current_pos[1]
            line_content = vim.fn.getline(line)
            moved_from_original = true
            goto continue
          end
          -- start == current, we start highlighting the word
          if moved_from_original == true then
            -- we already skipped the first character, for example, when we start at the space before a word
            -- so we don't need to keep skipping, for example, in " ((a"
            -- we start in space, we keep and moved_from_original is true, so we highlight all the non-word
            -- characters until we hit a word, so the result is "((" being highlighted
            if next_type == CharacterType.EndOfLine then break end
            if target == Utils.Targets.NextWordStart then
              if (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
                or (current_type == CharacterType.Punctuation and next_type == CharacterType.Word)
              then
                break
              end
            end

            -- NextLongWordStart doesn't need because punctuation and word are equal

            if target == Utils.Targets.NextWordEnd then
              if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
                or (current_type == CharacterType.Punctuation and next_type ~= CharacterType.Punctuation)
              then
                break
              end
            end

          else
            -- This is the first block to execute, we just started at the original, and didn't moved

            if target == Utils.Targets.NextWordStart then
              if (current_type ~= CharacterType.Punctuation and next_type == CharacterType.Punctuation)
                or (current_type == CharacterType.Punctuation and next_type == CharacterType.Word)
                or (current_type == CharacterType.WhiteSpace and next_type == CharacterType.Word)
              then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
            end

            if target == Utils.Targets.NextLongWordStart then
              if (current_type == CharacterType.WhiteSpace and next_type ~= CharacterType.WhiteSpace)
              then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
            end

            if target == Utils.Targets.NextWordEnd or target == Utils.Targets.NextLongWordEnd then
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
      end -- while
    end -- if prev
  hl_end = {current_pos[1], current_pos[2]}
  end -- for
  return { hl_start, hl_end }
end
return M
