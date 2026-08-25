# Harpoon keymap contract

Source of truth: [`config/nvim/lua/plugins/harpoon.lua`](../config/nvim/lua/plugins/harpoon.lua)

| | |
|---|---|
| Plugin | `ThePrimeagen/harpoon` branch `harpoon2` |
| Leader | `<Space>` (LazyVim) |
| Layout | QWERTY |

This is **not** ThePrimeagen's README map set. Those chords are Dvorak-oriented and they collide with this tree.

## Normal mode

| Chord | Call | Role |
|---|---|---|
| `<leader>a` | `list():add()` | mark current buffer |
| `<leader>h` | `ui:toggle_quick_menu(list())` | list UI |
| `<leader>1` … `<leader>4` | `list():select(n)` | hot slots; overflow lives in the menu |
| `[a` | `list():prev({ ui_nav_wrap = true })` | previous mark, wraps |
| `]a` | `list():next({ ui_nav_wrap = true })` | next mark, wraps |

Four hot slots is the point of Harpoon. Extra marks are still reachable from the menu.

## Menu buffer (buffer-local)

| Chord | Call |
|---|---|
| `1` … `9` | `list():select(n)` (`navigate_with_number`) |
| `<C-v>` | `select_menu_item({ vsplit = true })` |
| `<C-x>` | `select_menu_item({ split = true })` |
| `<C-t>` | `select_menu_item({ tabedit = true })` |

`j` / `k` / `<CR>` / `q` / `<Esc>` are stock Harpoon.

## Keys we do not take

These are occupied. Do not rebind Harpoon onto them without an explicit replacement.

| Chord | Owner | What breaks if Harpoon takes it |
|---|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | LazyVim | window move |
| `<C-s>` | LazyVim | write buffer (`n`/`i`/`x`/`s`) |
| `<A-j>` `<A-k>` | LazyVim | move line |
| `<M-1>` … `<M-9>` | tmux `bind -n` | window select, no prefix |
| `<C-S-P>` `<C-S-N>` | (dead in most ttys) | Ctrl-Shift collapses to Ctrl; Alacritty is not wired to distinguish them |
| `<leader>e` | LazyVim / neo-tree | file explorer |

`<C-e>` (native: scroll window one line) is left alone. The menu is already on `<leader>h`.

`<leader>a` is free **in this config**. LazyVim AI extras (`avante`, `copilot-chat`, `sidekick`, `claudecode`) claim it as a prefix. Do not enable those without remapping add.

## Persistence

Upstream defaults are both `false`. This spec turns them on:

```lua
settings = {
  save_on_toggle = true,   -- closing the menu writes the in-memory list
  sync_on_ui_close = true, -- closing the menu syncs the list to disk
}
```

List identity is `cwd` (`settings.key`). Not branch-scoped.

## Apply

Restart Neovim, or:

```
:Lazy reload harpoon
```

`~/.config/nvim` is a separate LazyVim tree, **not** a symlink into this repository. Copy `config/nvim/lua/plugins/harpoon.lua` there if that instance should match.
