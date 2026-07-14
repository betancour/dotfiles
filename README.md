# Dotfiles

Portable shell configuration for **Linux** and **macOS**, shared by **Bash** and **Zsh**.

One codebase. No shell-specific branches. Thin compatibility layers only where Bash and Zsh truly diverge.

## Quick start

```sh
git clone https://github.com/betancour/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles

# Install for your current login shell (auto-detect)
make install
# or: ./install.sh
# or: ./install.sh both   # both Bash and Zsh

exec "$SHELL" -l
```

## What gets installed

The installer (`scripts/install.sh`, POSIX `sh`) decides:

| Choice | Result |
|--------|--------|
| `zsh`  | Symlinks `config/shell/zsh/.*` → `$HOME` |
| `bash` | Symlinks `config/shell/bash/.*` → `$HOME` |
| `both` | Both of the above |
| `auto` | Detects from `$SHELL` (default) |

Existing files are **backed up**, not destroyed. Correct symlinks are left unchanged (idempotent).

## Architecture

```
config/shell/
├── lib/          # shared by Bash and Zsh (environment, path, aliases, login, …)
├── bash/         # Bash entry points + modules (options, prompt, completion, …)
└── zsh/          # Zsh entry points + modules (options, prompt, plugins, …)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for boot order, design decisions, and extension points.

## Requirements

- macOS or Linux
- Bash 3.2+ and/or Zsh 5+
- Standard POSIX utilities (`sh`, `ln`, `mkdir`, `date`, …)

### Recommended tools

Modern CLI tools are optional; aliases fall back to stock utilities.

```sh
# macOS
brew install eza bat ripgrep fzf fd zoxide neovim git-lfs

# Debian/Ubuntu
sudo apt install bat ripgrep fzf fd-find zoxide neovim git-lfs
```

### Optional Zsh plugins

If [Oh My Zsh](https://ohmyz.sh/) is installed, autosuggestions and syntax-highlighting plugins are loaded when present. Without OMZ, Homebrew/system plugin paths are tried automatically.

## Customization

Machine-specific settings belong in local files (never commit secrets):

```sh
# Created from template on first install if missing
$EDITOR ~/.zshrc.local    # or ~/.bashrc.local
$EDITOR ~/.gitconfig.local
```

Feature flags (export in a `*.local` file):

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_SHOW_LOGIN_INFO=1` | off | Login system banner |
| `DOTFILES_SHOW_DEV_STATUS=1` | off | Git/Node summary on login |
| `DOTFILES_SSH_ADD_CONFIRM=1` | off | Confirm each `ssh-add` |

## Make targets

```sh
make install        # auto-detect shell
make install-zsh
make install-bash
make install-both
make validate       # syntax-check all shell files
make lint           # shellcheck (if installed)
make clean          # remove broken symlinks in $HOME
```

## Performance

Startup stays lean by default:

- No login banners or docker probes unless enabled
- Lazy NVM / mise stubs
- Single-pass PATH construction
- Zsh completion dump reuse (`compinit -C` when fresh)

Profile Zsh startup:

```sh
ZSH_PROFILE_STARTUP=1 zsh -i -c 'zprof; exit'
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — structure, boot sequence, compatibility layer
- `config/terminal/.zshrc.local.template` / `.bashrc.local.template` — local examples

## License

[MIT](LICENSE)
