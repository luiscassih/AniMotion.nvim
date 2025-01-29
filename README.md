# AniKakoune
A pretty simple way to do a select-first word by word navigation in neovim similar to kakoune.

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

While I call this Kakoune mode, it's a little bit different, it's more a "word by word" selection first. In Kakoune, when you git w, you select up to the beginning of the next word without including it, so you also select the space if there is one. In this plugin, is like you go word by word doing "viw" and selecting only the word.

In the example `vim.cmd("normal! v")` if you are in the first `i` from `vim`, pressing w will select `vim`, pressing again will select `.`, again `cmd` and go on. If you are in the end of the line, pressing `w` will select the last word without jumping to the next line until you hit `w` again.

 If you want to select more than the word itself, you can use `W` or `B` like the default vim motion behavior. If you are in the middle and don't want to select the whole word, you can press `v` to enter visual and then `e` to the end or `b` to the beginning. This way you retain the motion muscle memory from vim but add a select-first approach only when it's the whole word.
