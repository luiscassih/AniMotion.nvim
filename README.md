# AniMotion.nvim
A Neovim plugin that implements selection-first text editing, similar to Kakoune and Helix editors. Lets you see your selection as you travel, allowing quick operations like change, delete, or yank. Works in normal mode with configurable selection modes.

## Installation
> Lazy basic defaults to "helix" mode
```lua
return {
  "luiscassih/AniMotion.nvim",
  event = "VeryLazy",
  config = true
}
```
> Default config
```lua
require("AniMotion").setup({
  mode = "helix", -- "nvim" or "word"
  word_keys = { "w", "b", "e", "W", "B", "E" },
  edit_keys = { "c", "d", "s", "r", "y" }, -- you can add "p" if you want.
  clear_keys = { "<Esc>" } -- used when you want to deselect/exit from SEL mode.
  marks = {"y", "z"}, -- Is a mark used internally in this plugin, when we do a visual select when changing or deleting the highlighted word.
  map_visual = true, -- When true, we capture "v" and pressing it will enter visual mode with the plugin selection as part of the visual selection. When false, pressing "v" will exit SEL mode and the selection will be lost. You want to set to false if you have trouble with other mappings associated to "v". I recommend to try in true first.
  color = { bg = "#673AB7" } -- put color = "Visual" to use the default visual mode color.
})
```

> For lualine users

You can have something like this to show an indicator if the plugin is in use.
```lua
ins_left {
  function()
    if (require("AniMotion").isActive()) then
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

Also, instead of having the cursor at the end of the word like in Kakoune, in this mode it will be at the start of the word, like in neovim, if you need to be at the end, just press `e` instead. `e` will also highlight the entire word like `w`. In the example before, both w and e will highlight the same way, but with w, the cursor will be at `v` -> `k` -> `s` -> `a`, while with e, the cursor will be at `m` -> `k` -> `s` -> `a`.

A succession of punctuation characters are also considered a word. `vim..keymap` will have this highlight flow -> `vim` -> `..` -> `keymap`.

Using `W` in this mode will highlight words alongside with punctuation only if they have just one punctuation in succession. For example `vim.keymap-set-key` will have the following highlight flow:
- Using `w`: `vim` -> `keymap` -> `set` -> `key`.
- Using `W`: `vim` -> `keymap-set-key`.

<!-- Also, inside quotes `'"` punctuation characters can be highlighted, for example normally in a string like `("a<")`, the punctuation `<` would not be highlighted unless it's more than one, like `a<<`, but in this mode pressing `w` when the cursor is at `(` will move and highlight `a<`, unless the string is `("aa<<<")`, on that case, `aa` and `<<<` are clear different words.  -->


## Notes
- This plugin works using the normal mode, so any key you press not captured by this plugin, it will behave normally. For example, if you have `K` mapped to lsp hover, even if you have any word selected using `w` (so in SEL mode), pressing `K` will show the hover normally.
