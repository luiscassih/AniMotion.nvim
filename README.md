# AniSelectFirst.nvim
A pretty simple way to do a select-first word by word navigation in neovim similar to kakoune.

## Bugs
[] - operation motions in visual mode doesn't work. For example, doing viw in normal mode select from cursor to next word instead of the current word at cursor.
[] - Other keys do not work well in visual mode, for example G does not go to the last line, and goes to the first line instead.

## Installation
> Lazy basic
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
  word_keys = { "w", "b", "e", "W", "B", "E" },
  edit_keys = { "c", "d", "s", "r" },
  marks = {"y", "z"}, -- used for visual select when changing or deleting the word
})
```

> For lualine users

You can have something like this to show an indicator if Kak mode is in use.
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

While I call this Kakoune mode, it's a little bit different, it's more a "word by word" selection first. In Kakoune, when you hit w, you select up to the beginning of the next word without including it, so you also select the space if there is one. In this plugin, is like you go word by word doing "viw" and selecting only the word.

In the example `vim.keymap.set(` if you are in the first `i` from `vim`, pressing w will select `vim`, pressing again will select `keymap`, again `set` and go on. If you are in the end of the line, pressing `w` will select the last word without jumping to the next line until you hit `w` again.

If you want to select more than the word itself, you can use `W` or `B` like the default vim motion behavior. If you are in the middle and don't want to select the whole word, you can press `v` to enter visual and then `e` to the end or `b` to the beginning. This way you retain the motion muscle memory from vim but add a select-first approach only when it's the whole word.

## Things to have in mind
- "i", "I", "a", "A" motions will not work while in Kak mode because they are complex and wait for more operation keys while in visual mode. So if you want to insert or append after selecting a word, you need to exit Kak mode first (for example, by pressing C-c or Esc)
