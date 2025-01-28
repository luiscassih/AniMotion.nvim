# AniKakoune
A pretty simple way to do a select-first navigation in neovim like kakoune

## Installation
> Lazy
```lua
return {
  dir = "~/dev/AniKakoune/",
  enabled = true,
  event = "VeryLazy",
  config = function()
    require("AniKakoune").setup({
      -- default config, just call setup()
      word_keys = { "w", "b", "e", "W", "B", "E" },
      disable_keys = {
        "i", "a", "I", "A",
        "h", "j", "k", "l", "f", "F", "t", "T", "/", "?", "n", "N",
        "gg", "G", "$", "_", "0",
        "H", "L", "J", "K",
        "<C-d>", "<C-u>",
      },
    })
  end
}
```

> For lualine users

You can set this to have an indicator
```lua
ins_left {
  function()
    if (require("AniKakoune").isKakouneMode()) then
      return "◎ Kak"
    end
    return ""
  end,
  color = { fg = colors.red, gui = 'bold' },
}
```

## Explanation
With word_keys you activate Kak mode, which just select the word first. If you continue pressing, it will deselect and select with the next word movement.

With disable_keys you deactivate the mode, which just means you can use the default behavior.

