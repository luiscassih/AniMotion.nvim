local Utils = require('AniMotion.utils')
local CharacterType = Utils.CharacterType
local M = {}

M.word_move = function(target, count)
  if target == Utils.Targets.NextWordEnd
    or target == Utils.Targets.NextLongWordEnd
    or target == Utils.Targets.NextLongWordStart
    or target == Utils.Targets.PrevLongWordStart
  then
    local helix = require('AniMotion.helix')
    if target == Utils.Targets.NextLongWordStart then
      target = Utils.Targets.NextWordStart
    end
    if target == Utils.Targets.PrevLongWordStart then
      target = Utils.Targets.PrevWordStart
    end
    return helix.word_move(target, count)
  end

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

          if (current_type ~= prev_type)
          then
            break
          end
        else
          if current_type == CharacterType.EndOfLine
            or prev_type == CharacterType.EndOfLine
          then
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
            goto continue
          end
          if moved_from_original == true then
            if prev_type == CharacterType.EndOfLine then break end

            if (current_type == CharacterType.Word and prev_type ~= CharacterType.Word)
            then
              break
            end
            if (current_type ~= CharacterType.Word)
            then
              hl_start[2] = hl_start[2] - 1
            end
          else
            if (current_type ~= prev_type)
              or (current_type == CharacterType.WhiteSpace)
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
            if (current_type ~= next_type)
            then
              break
            end
          end

          -- if target == Utils.Targets.NextLongWordStart then
          --   if (current_type ~= next_type and next_char ~= '-' and current_char ~= '-')
          --   then
          --     break
          --   end
          -- end

        else
          if current_type == CharacterType.EndOfLine
            or next_type == CharacterType.EndOfLine
          then
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
              if (current_type == CharacterType.Word and next_type ~= CharacterType.Word)
              then
                break
              end
              if (current_type ~= CharacterType.Word)
              then
                hl_start[2] = hl_start[2] + 1
              end
            end

            -- if target == Utils.Targets.NextLongWordStart then
            --   if (current_type == CharacterType.Word and next_type ~= CharacterType.Word and next_char ~= '-')
            --   then
            --     break
            --   end
            --   if (current_type ~= CharacterType.Word)
            --   then
            --     hl_start[2] = hl_start[2] + 1
            --   end
            -- end

          else
            -- This is the first block to execute, we just started at the original, and didn't moved
            if target == Utils.Targets.NextWordStart then
              if (current_type ~= next_type)
                or (current_type == CharacterType.WhiteSpace)
              then
                hl_start[2] = hl_start[2] + 1
                moved_from_original = true
              end
            end

            -- if target == Utils.Targets.NextLongWordStart then
            --   if (current_type ~= next_type and next_char ~= '-' and current_char ~= '-')
            --     or (current_type == CharacterType.WhiteSpace)
            --   then
            --     hl_start[2] = hl_start[2] + 1
            --     moved_from_original = true
            --   end
            -- end
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
