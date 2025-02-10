# AniMotion.nvim
A Neovim plugin that implements selection-first text editing, similar to Helix and Kakoune editors. Lets you see your selection as you travel, allowing quick operations like change, delete, or yank. Works in normal mode with configurable selection modes.

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
  mode = "helix", -- "nvim" or "animotion"
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

> helix - default

In this mode, word motions keys will behave helix (or kakoune), it's a bit different than neovim, for example pressing `w` on a word will go up until we hit a non whitespace character. In `Hello world`, pressing at `H` will move the cursor to the space and will select `Hello `.

> nvim

In this mode, word motions keys will behave the same as neovim, pressing `w` will go to the first character of the next word. In `Hello world`, pressing at `H` will move the cursor to `w` and will select `Hello w`. <br/>
You probably will not want to use this mode unless you're so used with the default `w` behavior of neovim and only want to enable the "select first" approach.

> animotion

This is my personal mode, for `w` and `b`, instead of highlighting spaces and punctuation characters, it's selects words by words. For example, in `vim.keymap.set("a"`, w will select `vim`, w again `keymap`, w again `set`, w again `a`. I find this approach to be more productive. The rest of jumps `e` `E` will go to helix mode, and `W` `B` will also go to helix mode but with the short jump instead. `W` will behave as `w` and `B` as `b` with helix mode.

So, this mode is an hybrid helix with a custom `w` `b`. The mind approach for this mode is: "Most of the time I only want to change words, so I keep pressing `w`, if I need to change punctuation, I press `W`"


## Notes
- This plugin works using the normal mode, so any key you press not captured by this plugin, it will behave normally. For example, if you have `K` mapped to lsp hover, even if you have any word selected using `w` (so in SEL mode), pressing `K` will show the hover normally.
