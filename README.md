# Dotfiles

Portable, production-grade shell configuration for **Linux** and **macOS**, shared by **Bash**, **Zsh**, and **POSIX sh**.

One real Git repository at **`~/.dotfiles`** is the single source of truth. Every configuration file under `$HOME` is a symbolic link into that repository. This is the traditional Unix dotfiles layout.

## Quick start

```sh
git clone https://github.com/betancour/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Preview changes
./install.sh --dry-run

# Install for your current login shell (auto-detect) + dependencies
./install.sh

# Or via Make
make install

exec "$SHELL" -l
```

The repository **must** live at `~/.dotfiles` as a real directory (not a symlink). If you run the installer from another path, it refuses or offers to move the repository to `~/.dotfiles` before proceeding.

## Model

| Location | Role |
|----------|------|
| `~/.dotfiles/` | Real Git repository (single source of truth) |
| `~/.dotfiles/.git` | Git metadata |
| `~/.zshrc`, `~/.gitconfig`, … | Symlinks → files inside `~/.dotfiles` |

There is no second copy of the repository under `~/dotfiles`, `~/Development`, or elsewhere.

Example home links after install:

```text
~/.gitconfig              → ~/.dotfiles/git/gitconfig
~/.gitignore_global       → ~/.dotfiles/git/gitignore_global
~/.vimrc                  → ~/.dotfiles/vim/vimrc
~/.zshrc                  → ~/.dotfiles/shell/zsh/.zshrc
~/.zprofile               → ~/.dotfiles/shell/zsh/.zprofile
~/.zlogin                 → ~/.dotfiles/shell/zsh/.zlogin
~/.zlogout                → ~/.dotfiles/shell/zsh/.zlogout
~/.zshenv                 → ~/.dotfiles/shell/zsh/.zshenv
~/.zaliases               → ~/.dotfiles/shell/.zaliases
~/.zfunctions             → ~/.dotfiles/shell/.zfunctions
~/.config/alacritty       → ~/.dotfiles/config/alacritty
~/.config/eza             → ~/.dotfiles/config/eza
~/.config/starship.toml   → ~/.dotfiles/config/starship/starship.toml
~/.config/tmux/tmux.conf  → ~/.dotfiles/config/tmux/tmux.conf
~/.config/zellij          → ~/.dotfiles/config/zellij
~/.grok/config.toml       → ~/.dotfiles/config/grok/config.toml
```

Grok credentials stay in `~/.grok/auth.json` and are never tracked. `~/.config/nvim` is a LazyVim tree; the installer links overlay files (Green Phosphor colorscheme, statusline, harpoon, …) into it.

## What the installer does

| Step | Behavior |
|------|----------|
| Preflight | Validates `HOME`, layout, required utilities |
| Detect | OS, architecture, package manager, privileges, default shell |
| Repository root | Requires `~/.dotfiles` (physical dir); offers to move if run elsewhere |
| Dependencies | Installs CLI tools via apt/dnf/yum/pacman/zypper/apk/brew |
| Shell config | Symlinks entry points (or `--append` managed blocks) |
| Git / Vim / Starship / Alacritty / tmux / Zellij / Waybar / Grok / Neovim overlay | Config links |
| Journal | Records actions for rollback / uninstall |

### Shell targets

```sh
./install.sh              # auto (from $SHELL)
./install.sh zsh
./install.sh bash
./install.sh sh           # POSIX .profile
./install.sh both         # bash + zsh
./install.sh all          # bash + zsh + sh
```

### Safety options

```sh
./install.sh --dry-run          # no mutations
./install.sh --force            # backup + replace conflicts
./install.sh --yes              # non-interactive; auto-move repo to ~/.dotfiles if needed
./install.sh --append           # keep existing rc files; inject source block
./install.sh --skip-deps        # config only
./install.sh --only-deps        # packages only
./install.sh --no-optional      # skip starship / shellcheck
./install.sh -v                 # verbose
```

Existing files are **never overwritten** without `--force`, `--yes`, or an interactive confirmation. Backups go to `~/.dotfiles_backups/<timestamp>/`.

### Uninstall

```sh
./uninstall.sh
./uninstall.sh --dry-run
make uninstall
```

Removes managed symlinks and managed blocks. Leaves the repository at `~/.dotfiles`, `*.local` overrides, and installed packages intact.

## Repository layout

```
~/.dotfiles/                   # real Git repository (canonical source of truth)
├── install.sh                 # main installer (POSIX sh)
├── uninstall.sh               # safe removal
├── bootstrap/                 # enforces ~/.dotfiles as the real repo root
├── lib/                       # installer modules
│   ├── common.sh
│   ├── logging.sh
│   ├── detect.sh
│   ├── package.sh
│   ├── deps.sh
│   ├── symlink.sh
│   ├── managed.sh
│   ├── shell_install.sh
│   └── rollback.sh
├── shell/                     # shell runtime (source of truth for rc files)
│   ├── lib/                   # SHARED runtime (bash + zsh)
│   ├── bash/
│   ├── zsh/
│   ├── sh/
│   ├── .zaliases
│   └── .zfunctions
├── config/                    # app configs (XDG-style)
│   ├── nvim/          # LazyVim overlay (Green Phosphor, harpoon, …)
│   ├── alacritty/     # Green Phosphor theme (symlink → ~/.config/alacritty)
│   ├── grok/          # Grok Build config.toml (no credentials)
│   ├── zellij/
│   ├── tmux/
│   ├── starship/
│   ├── terminal/
│   └── …
├── git/                       # gitconfig + global gitignore
├── vim/
├── scripts/install.sh
├── docs/
│   ├── ARCHITECTURE.md
│   └── HARPOON.md          # Neovim Harpoon keymap contract
└── Makefile
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for boot order and design decisions. Harpoon maps: [docs/HARPOON.md](docs/HARPOON.md).

## Dependencies

The installer detects the OS package manager and installs:

| Logical name | Purpose | Fallback if missing |
|--------------|---------|---------------------|
| `zoxide` | smarter `cd` | builtin `cd` |
| `fzf` | fuzzy finder | — |
| `ripgrep` | search | `grep` |
| `fd` | find | — (`fdfind` on Debian) |
| `bat` | richer `cat` | `cat` (`batcat` on Debian) |
| `eza` | richer `ls` | `ls` / `exa` |
| `direnv` | per-directory env | — |
| `bash-completion` / `zsh-completions` | completions | — |
| `starship` | prompt (optional) | built-in git prompt |
| `git`, `curl` | core | — |

Supported managers: **apt**, **dnf**, **yum**, **pacman**, **zypper**, **apk**, **brew**.

## Customization

Machine-specific settings belong in local files (never commit secrets):

```sh
$EDITOR ~/.zshrc.local      # or ~/.bashrc.local / ~/.profile.local
$EDITOR ~/.gitconfig.local
```

Feature flags (export in a `*.local` file):

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_SHOW_LOGIN_INFO=1` | off | Login system banner |
| `DOTFILES_SHOW_DEV_STATUS=1` | off | Git/Node summary on login |
| `DOTFILES_SSH_ADD_CONFIRM=1` | off | Confirm each `ssh-add` |
| `DOTFILES_USE_OMZ=1` | off | Load the Oh My Zsh framework (slow; standalone plugins are the default) |

On every top-level terminal start you also get a compact start line (always on): session start time, system uptime since last reboot, and shell ready time.

## Make targets

```sh
make install          # auto-detect shell
make install-zsh
make install-bash
make install-sh
make install-both
make install-all
make install-deps
make install-java-tools   # latest stable Maven + Gradle → ~/.java-tools
make update-java-tools    # same; upgrades only when a newer release exists
make java-tools-status
make dry-run
make uninstall
make validate         # syntax-check all shell files + installer
make lint             # shellcheck (if installed)
make clean            # remove broken symlinks in $HOME
```

## Java tools (Maven + Gradle)

Maven and Gradle are **not** installed by `./install.sh` and are **never** updated at shell startup. Install or upgrade them on demand:

```sh
make install-java-tools          # or: install-java-tools
make update-java-tools           # same script; skips when already current
scripts/install-java-tools.sh --dry-run
scripts/install-java-tools.sh status
```

The script discovers the latest **stable** Maven (GA versions from Maven Central metadata; previews such as 4.0.0-rc are skipped) and the latest **stable** Gradle (official `services.gradle.org/versions/current` JSON), verifies checksums, and installs under `~/.java-tools/`. `MAVEN_HOME`, `GRADLE_HOME`, and `PATH` are set by `shell/lib/environment.sh` and `shell/lib/path.sh` when those directories exist.

## Performance

Startup stays lean by default:

- No login banners or docker probes unless enabled
- Lazy NVM / mise / pyenv / rbenv stubs
- Oh My Zsh framework off unless `DOTFILES_USE_OMZ=1` (avoids a second `compinit`)
- Cached `starship` / `zoxide` / `direnv` / `kubectl` init scripts
- Single-pass PATH construction
- Zsh completion dump reuse (`compinit -C` when fresh)
- Starship used only when installed; otherwise lightweight git prompts

Profile Zsh startup:

```sh
ZSH_PROFILE_STARTUP=1 zsh -i -c 'zprof; exit'
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — structure, boot sequence, installer design
- `config/terminal/.zshrc.local.template` / `.bashrc.local.template` — local examples

## License

[MIT](LICENSE)
