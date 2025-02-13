# AniMotion.nvim
A Neovim plugin that implements selection-first text editing, similar to Helix and Kakoune editors. Lets you see your selection as you travel, allowing quick operations like change, delete, or yank. Works in normal mode without entering visual mode and several configurable selection modes.

## Installation
> Lazy basic defaults to "helix" mode
```lua
return {
  "luiscassih/AniMotion.nvim",
  event = "VeryLazy",
  config = true
}
```

> Basic config with helix and default Visual highlight color

```lua
return {
  "luiscassih/AniKakoune",
  event = "VeryLazy",
  config = function()
    require("AniMotion").setup({
      mode = "helix",
      clear_keys = { "<C-c>" },
      color = "Visual",
    })
  end
}
```

> Default config
```lua
require("AniMotion").setup({
  mode = "animotion", -- "nvim" or "helix"
  word_keys = {
    [Utils.Targets.NextWordStart] = "w",
    [Utils.Targets.NextWordEnd] = "e",
    [Utils.Targets.PrevWordStart] = "b",
    [Utils.Targets.NextLongWordStart] = "W",
    [Utils.Targets.NextLongWordEnd] = "E",
    [Utils.Targets.PrevLongWordStart] = "B",
  }, -- you can get the targets by local Utils = require("Animotion.Utils")
  edit_keys = { "c", "d", "s", "r", "y" }, -- you can add "p" if you want.
  clear_keys = { "<Esc>" } -- used when you want to deselect/exit from SEL mode.
  marks = {"y", "z"}, -- Is a mark used internally in this plugin, when we do a visual select when changing or deleting the highlighted word.
  map_visual = true, -- When true, we capture "v" and pressing it will enter visual mode with the plugin selection as part of the visual selection. When false, pressing "v" will exit SEL mode and the selection will be lost. You want to set to false if you have trouble with other mappings associated to "v". I recommend to try in true first.
  color = { bg = "#673AB7" } -- put color = "Visual" to use the default visual mode color. You can also customize via vim.api.nvim_set_hl(0, "@AniMotion", hl_color)
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

## Different modes

> animotion - default

This is my personal mode for `w` and `b`. Instead of highlighting spaces and punctuation characters, it selects words one at a time. For example, in `vim.keymap.set("a")`, pressing `w` will select `vim`, pressing it again selects `keymap`, then `set`, and finally `a`. I find this approach more productive. The remaining jump commands `e` and `E` use Helix mode, while `W` and `B` (with shift) also use Helix mode but with shorter jumps. In other words, `W` behaves like Helix's `w`, and `B` like Helix's `b`.

This mode is a hybrid between Helix and a custom `w`/`b` implementation. The philosophy behind this mode is: "Most of the time I only want to change words, so I keep pressing `w`. If I need to change punctuation, I press `W`."

> helix

In this mode, word motion keys behave like in Helix (or Kakoune). It's slightly different from Neovim. For example, pressing `w` on a word will move until it hits a non-whitespace character. In `Hello world`, pressing `w` while on `H` will move the cursor to the space and select `Hello `.

> nvim

In this mode, word motion keys behave exactly like in Neovim. Pressing `w` will go to the first character of the next word. In `Hello world`, pressing `w` while on `H` will move the cursor to `w` and select `Hello w`. <br/>
You might want to use this mode if you're very familiar with Neovim's default `w` behavior and only want to enable the "select first" approach.

## Motivation and reason of existence

I love Neovim and can't imagine coding without it anymore. That being said, I was intrigued by the visual selection-first approach of Helix and Kakoune. However, I didn't want to spend so much time getting used to their keybinds, and using Vim keybinds in Helix didn't feel right, so I decided to make this plugin.

The main feature I liked from Helix was the selection navigation using `w` and `b`. While in Vim we have `viw` which is great, navigating and changing words quickly with Helix felt more natural. Bringing this motion was the main motivation for this plugin. As for the other motions, I didn't see the need to change them, as Neovim's motions cover all of them naturally. Want to select a paragraph? `vip`. The same goes for blocks, quotes, up to a character, and so on.

After experimenting with Helix-style `w` and `b` motions, I noticed that what I really wanted was to hop by words repeatedly. While Helix does that, it also selects spaces and hops between punctuation. For example, with code like `object.function()` or `pointer->member`, you usually want to change the name of the function, member, or object – you rarely want to change the punctuation, so jumping at each `.` or `->` or `(` feels like wasted motions. In `Object.getInstance().function()`, you have to press `w` 5 times to get to `function` in Helix, while with `animotion` you only need to press it 3 times. It might not seem like a big difference, but in practice it makes a significant improvement and feels more natural. If you still need to jump between punctuation, you can use shift (`W`), which will behave the same as Helix, giving you the best of both worlds.

## Notes
- This plugin works in normal mode, so any key you press that isn't captured by this plugin will behave normally. For example, if you have `K` mapped to LSP hover, even when you have a word selected using `w` (in SEL mode), pressing `K` will show the hover normally.
