# Alacritty configuration

Modular, XDG-friendly Alacritty config for Alacritty **≥ 0.13** (TOML).

## Layout

| File | Role |
|------|------|
| `alacritty.toml` | Entrypoint — import order only |
| `theme.toml` | **Switch theme** (one import path) |
| `font.toml` | **Switch font** (one import path) |
| `font-size.toml` | Size / glyph offset (per-machine friendly) |
| `terminal.toml` | Shell, env, scrollback, cursor, selection, mouse |
| `window.toml` | Padding, opacity, decorations, dimensions |
| `keys.toml` | Extra keybindings |
| `btop.toml` | Alternate profile for system-monitor launchers |
| `themes/` | Color schemes |
| `fonts/` | Typeface definitions |

Import rule (Alacritty): files load left→right; **later wins** on conflicts. Paths are relative to this directory so the tree works when symlinked to `~/.config/alacritty`.

## Install

The dotfiles installer links this directory:

```sh
~/.config/alacritty  →  ~/.dotfiles/config/alacritty
```

```sh
./install.sh --skip-deps   # or full install
```

If you already have a real directory at `~/.config/alacritty`, use `--force` (existing tree is backed up first).

## Switch theme / font

Edit only the switch files:

```toml
# theme.toml
import = ["themes/nord.toml"]

# font.toml
import = ["fonts/JetBrainsMono.toml"]
```

Live reload is enabled (`live_config_reload = true`); most changes apply without restart. Window dimensions and shell still require a restart.

## Shell / multiplexers

Default shell is a **login zsh** (`/bin/zsh -l`). Multiplexers (tmux, zellij) are **not** forced here so:

- Alacritty still opens if the multiplexer binary is missing
- Nested sessions are avoided when spawning new windows
- Desktop entries can pass `-e btop` / `-e htop` cleanly

Start a multiplexer from the shell, or from a launcher:

```sh
alacritty -e tmux
alacritty --config-file ~/.config/alacritty/btop.toml -e btop
```

To force a multiplexer from Alacritty again, override in `terminal.toml`:

```toml
[terminal.shell]
program = "/bin/zsh"
args = ["-l", "-c", "tmux"]
```

## Validate

```sh
# Syntax
python3 -c 'import tomllib, pathlib; [tomllib.load(p.open("rb")) for p in pathlib.Path(".").rglob("*.toml")]'

# Load without a long-lived window
alacritty --config-file ./alacritty.toml --daemon -vv &
# check logs for "Configuration files loaded" / errors, then:
alacritty msg create-window -e true   # optional
pkill -f 'alacritty --config-file ./alacritty.toml --daemon'
```

Requires Alacritty on `PATH` and fonts installed for the active typeface (`fc-list 'Cascadia Code NF'`).
