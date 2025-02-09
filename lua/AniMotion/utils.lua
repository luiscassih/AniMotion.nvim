local M = {}

M.Targets = {
  NextWordStart = 1, -- w
  NextWordEnd = 2, -- e
  PrevWordStart = 3, -- b
  NextLongWordStart = 4, -- W
  NextLongWordEnd = 5, -- E
  PrevLongWordStart = 6, -- B
}

M.CharacterType = {
  WhiteSpace = 1,
  Word = 2,
  Punctuation = 3,
  EndOfLine = 4,
  Unknown = 5
}

M.get_character_type = function(char)
  if char == '\n' then
    return M.CharacterType.EndOfLine
  end
  if char:match('%s') then
    return M.CharacterType.WhiteSpace
  end
  if char:match('[%w_]') then
    return M.CharacterType.Word
  end
  if char:match('[^%s%w_]') then
    return M.CharacterType.Punctuation
  end
  return M.CharacterType.Unknown
end

M.get_next_char = function(currentPos, line_content)
  return currentPos[2] < #line_content and line_content:sub(currentPos[2] + 1, currentPos[2] + 1) or '\n'
end

M.get_current_char = function(currentPos, line_content)
  return line_content:sub(currentPos[2], currentPos[2])
end

M.get_prev_char = function(currentPos, line_content)
  return currentPos[2] > 1 and line_content:sub(currentPos[2] - 1, currentPos[2] - 1) or '\n'
end

return M
