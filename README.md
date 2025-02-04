# AniSelectFirst.nvim
A neovim plugin to add a select-first approach into normal mode, inspired by helix/kakoune.

## Installation
> Lazy basic defaults to "nvim" mode
```lua
return {
  "luiscassih/AniKakoune",
  event = "VeryLazy",
  config = true
}
```
> Default config
```lua
require("AniKakoune").setup({
  mode = "kakoune", -- "nvim" or "word"
  word_keys = { "w", "b", "e", "W", "B", "E" },
  edit_keys = { "c", "d", "s", "r", "y" }, -- you can add "p" if you want.
  exit_keys = {"<Esc>", "<C-c>"} -- used when you want to deselect/exit from SEL mode.
  marks = {"y", "z"}, -- Is a mark used internally in this plugin, when we do a visual select when changing or deleting the highlighted word.
  map_visual = true, -- When true, we capture "v" and pressing it will enter visual mode with the plugin selection as part of the visual selection. When false, pressing "v" will exit SEL mode and the selection will be lost. You want to set to false if you have trouble with other mappings associated to "v". I recommend to try in true first.
})
```

> For lualine users

You can have something like this to show an indicator if Kak mode is in use.
```lua
ins_left {
  function()
    if (require("AniKakoune").isActive()) then
      return "◎ SEL"
    end
    return ""
  end,
  color = { fg = colors.red, gui = 'bold' },
}
```

## Diferent modes

> kakoune - default

In this mode, word motions keys will behave kakoune (or helix), it's a bit different than neovim, for example pressing `w` on a word will go up until we hit a non whitespace character. In `Hello world`, pressing at `H` will move the cursor to the space and will select `Hello `.

> nvim

In this mode, word motions keys will behave the same as neovim, pressing `w` will go to the first character of the next word. In `Hello world`, pressing at `H` will move the cursor to `w` and will select `Hello w`. <br/>
You probably will not want to use this mode unless you're so used with the default `w` behavior of neovim and only want to enable the "select first" approach.

> word

This is my personal mode, it's similar to kakoune, but instead of highlighting spaces and punctuation characters, it's selects words by words. For example, in `vim.keymap.set("a"`, w will select `vim`, w again `keymap`, w again `set`, w again `a`. I find this approach to be more productive.


## Notes
- This plugin works using the normal mode, so any key you press not captured by this plugin, it will behave normally. For example, if you have `K` mapped to lsp hover, even if you have any word selected using `w` (so in SEL mode), pressing `K` will show the hover normally.