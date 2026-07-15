# Architecture

Professional-grade multi-shell dotfiles with a modular POSIX installer.

## Design principles

1. **Do one thing well** — each library module has one job.
2. **Share by default** — Bash and Zsh load the same `shell/lib/` modules.
3. **One real repository** — `~/.dotfiles` is a physical Git directory (never a symlink); `$HOME` only holds symlinks into it.
4. **Isolate the unavoidable** — shell-specific code lives only in thin modules.
5. **POSIX where practical** — installer is pure `/bin/sh`; shared interactive code uses the Bash/Zsh common dialect.
6. **Configuration over conditionals** — feature flags in `privacy.sh` and `*.local` files.
7. **Fast startup** — no login banners, docker probes, or heavy tool init by default.
8. **Idempotent install** — correct symlinks are left alone; conflicts require confirmation or `--force`.
9. **Safe by default** — backups, journals, rollback, dry-run, never clobber without consent.
10. **Fail usefully** — preflight checks, colored logs, dependency verification.

## Canonical layout

```
~/.dotfiles/                 # physical directory — the only Git repository
~/.dotfiles/.git/            # Git metadata
~/.zshrc  →  ~/.dotfiles/shell/zsh/.zshrc
~/.gitconfig  →  ~/.dotfiles/git/gitconfig
…
```

Rules:

- `~/.dotfiles` is **not** a symbolic link.
- There is **no** second copy under `~/dotfiles`, `~/Development/dotfiles`, or similar.
- The installer verifies it is running from `~/.dotfiles`. If run elsewhere, it refuses or offers to `mv` the tree to `~/.dotfiles` (preserving history) before continuing.

## Supported platforms

| Platform | Shells            | Package managers              | Status  |
|----------|-------------------|-------------------------------|---------|
| macOS    | Bash, Zsh, sh     | brew                          | Primary |
| Linux    | Bash, Zsh, sh     | apt, dnf, yum, pacman, zypper, apk | Primary |

No separate branches. One tree serves all supported shells and OSes.

## Directory layout

```
~/.dotfiles/                   # real Git repository (canonical source of truth)
├── install.sh                 # orchestrator (CLI, traps, pipeline)
├── uninstall.sh               # reverse of install (symlinks + managed blocks)
├── bootstrap/
│   └── ensure-dotfiles-home.sh  # require/move to ~/.dotfiles
├── lib/                       # installer-only modules (not sourced at shell startup)
│   ├── common.sh              # constants, paths, confirm, realpath
│   ├── logging.sh             # colors, levels, file log
│   ├── detect.sh              # OS / arch / pkg / shell / privileges
│   ├── package.sh             # manager abstraction
│   ├── deps.sh                # package sets, verify, post-link helpers
│   ├── symlink.sh             # link + backup + force policy
│   ├── managed.sh             # append-mode BEGIN/END blocks
│   ├── shell_install.sh       # shell / git / vim / starship
│   └── rollback.sh            # journal reverse
├── shell/                     # shell runtime (rc files live here)
│   ├── lib/                   # SHARED runtime — sourced by Bash and Zsh
│   ├── bash/                  # Bash compatibility layer
│   ├── zsh/                   # Zsh compatibility layer
│   ├── sh/                    # POSIX sh profile + tools
│   ├── .zaliases
│   └── .zfunctions
├── config/                    # app configs
│   ├── nvim/
│   ├── alacritty/
│   ├── zellij/
│   ├── tmux/
│   ├── starship/
│   └── terminal/
├── git/
├── vim/
├── scripts/install.sh         # compatibility wrapper
└── docs/
```

## Installer pipeline

```
parse_args
  → preflight
  → detect (OS, arch, pkg, shell, privileges)
  → version checks
  → journal + manifest init
  → resolve repository root (require ~/.dotfiles; offer move)
  → install dependencies (unless --skip-deps)
  → install shell config (symlink | --append)
  → install git / vim / starship
  → summary
```

On unexpected failure, `EXIT` trap invokes journal rollback.

### Modes

| Mode | Flag | Behavior |
|------|------|----------|
| Symlink (default) | — | Entry points in `$HOME` → repo files |
| Append | `--append` | Keep user rc files; inject managed `source` block |
| Dry-run | `--dry-run` / `-n` | Log actions only |
| Force | `--force` / `-f` | Backup + replace without prompting |
| Yes | `--yes` / `-y` | Auto-confirm prompts; auto-move repo if needed |
| Deps only | `--only-deps` | Packages only |
| Config only | `--skip-deps` | No package installs |

### Package manager mapping

Logical tool names (`zoxide`, `fd`, `bat`, …) map to distro packages (`fd-find`, `bat` / `batcat`, …). After install, Debian renames are normalized via `~/.local/bin` wrappers.

### State files

| Path | Purpose |
|------|---------|
| `~/.local/state/dotfiles/install.journal` | Ordered actions for rollback |
| `~/.local/state/dotfiles/install.manifest` | Last successful install metadata |
| `~/.local/state/dotfiles/symlinks.list` | Dest paths we created |
| `~/.local/state/dotfiles/managed.list` | Files with managed blocks |
| `~/.local/state/dotfiles/install.log` | Append-only log |
| `~/.dotfiles_backups/<ts>/` | Backed-up user files |

## Boot sequence

### Zsh (login interactive)

```
.zshenv     → bootstrap + environment + HISTFILE
.zprofile   → profile (brew, ssh-agent, version managers)
.zshrc      → options, history, completion, plugins, prompt, tools, aliases, functions
.zlogin     → login (optional banners, update check, agent restore)
.zlogout    → logout (history backup, agent teardown, farewell)
```

### Bash (login interactive)

```
.bash_profile → bootstrap + environment + profile → .bashrc → .bash_login
.bashrc       → options, history, prompt, completion, keybindings, tools, aliases, functions
.bash_login   → login
.bash_logout  → logout
```

Non-login interactive Bash loads only `.bashrc` (which still pulls environment).

### POSIX sh (login)

```
.profile → path, editor, platform, modules/tools.sh → .profile.local
```

Provides aliases and lightweight hooks (zoxide/direnv/starship when available) without Bash/Zsh features.

## Compatibility layer

Shell-specific modules exist **only** where POSIX/shared code cannot express the feature:

| Concern        | Shared (`lib/`)     | Bash module              | Zsh module                | sh |
|----------------|---------------------|--------------------------|---------------------------|----|
| Options        | —                   | `shopt`                  | `setopt`                  | — |
| Completion     | —                   | bash-completion          | `compinit` / zstyle       | — |
| Key bindings   | —                   | readline `bind`          | ZLE `bindkey`             | — |
| Prompt         | —                   | `PS1` + git funcs        | `PROMPT` + `vcs_info`     | basic PS1 |
| Starship       | —                   | `starship init bash`     | `starship init zsh`       | best-effort |
| Plugins        | —                   | —                        | OMZ / autosuggestions     | — |
| Tool hooks     | fzf defaults, nvm   | zoxide/direnv/fzf bash   | zoxide/direnv/fzf zsh     | subset |
| Profile/login  | **all shared**      | thin entry points        | thin entry points         | `.profile` |

`DOTFILES_SHELL` is set in `bootstrap.sh` (`bash` | `zsh` | `sh`) so shared code can branch only when necessary.

## Feature flags

Set in environment or `*.local` files:

| Variable                    | Default | Effect                          |
|-----------------------------|---------|---------------------------------|
| `DOTFILES_SHOW_LOGIN_INFO`  | `0`     | Welcome banner with sys stats   |
| `DOTFILES_SHOW_DEV_STATUS`  | `0`     | Git/Node summary on login       |
| `DOTFILES_SSH_ADD_CONFIRM`  | `0`     | `ssh-add -c` per key            |
| `ZSH_PROFILE_STARTUP`       | unset   | Print `zprof` after `.zshrc`    |

## Local customization

Never edit tracked files for machine-specific settings. Use:

- `~/.zshrc.local` / `~/.bashrc.local` / `~/.profile.local`
- `~/.zprofile.local` / `~/.bash_profile.local`
- `~/.zshenv.local` / `~/.bash_env.local`
- `~/.gitconfig.local`

Templates live under `config/terminal/` and `git/`.

## Performance notes

- Platform flags are computed once in `platform.sh`.
- Login banners and docker probes are off by default.
- NVM and mise are lazy stubs until first invocation.
- Zsh reuses `.zcompdump` for 24h (`compinit -C`).
- PATH is built in a single pass with duplicate checks.
- Shared modules use source-once markers to avoid re-work.
- Native git prompts are skipped when `starship` is on `PATH`.

## Extending

**New shared alias/function:** edit `shell/lib/aliases.sh` or `functions.sh` (exposed via `shell/.zaliases` / `shell/.zfunctions`).

**New shell-specific option:** edit `shell/bash/modules/options.bash` or `shell/zsh/modules/options.zsh`.

**New dependency:** add logical name to `lib/deps.sh` and a mapping in `lib/package.sh` (`df_pkg_name`).

**New OS support:** extend `lib/detect.sh` / `package.sh`; prefer capability detection over OS switches.

**New shell (e.g. fish):** not targeted — would need a separate runtime model.

## Installer quality bar

- Strict mode (`set -eu`) on entry points
- ShellCheck-clean POSIX modules under `lib/`
- Colored, leveled logging with optional file log
- Dry-run, verbose, force, yes, append
- Privilege detection (skip system packages when impossible)
- Dependency verification after install
- Uninstall path that will not delete user `*.local` files
