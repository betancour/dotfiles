# Architecture

Professional-grade, dual-shell dotfiles with a single shared codebase.

## Design principles

1. **Do one thing well** — each library module has one job.
2. **Share by default** — Bash and Zsh load the same `lib/` modules.
3. **Isolate the unavoidable** — shell-specific code lives only in thin modules.
4. **POSIX where practical** — installer is pure `/bin/sh`; shared interactive code uses the Bash/Zsh common dialect.
5. **Configuration over conditionals** — feature flags in `privacy.sh` and `*.local` files.
6. **Fast startup** — no login banners, docker probes, or heavy tool init by default.
7. **Idempotent install** — correct symlinks are left alone; conflicts are backed up.

## Supported platforms

| Platform | Shells   | Status        |
|----------|----------|---------------|
| macOS    | Bash, Zsh| Primary       |
| Linux    | Bash, Zsh| Primary       |

No separate branches. One tree serves both shells and both OSes.

## Directory layout

```
dotfiles/
├── install.sh                 # thin wrapper → scripts/install.sh
├── scripts/install.sh         # POSIX installer (decides shell/OS deploy)
├── Makefile
├── config/
│   ├── shell/
│   │   ├── lib/               # SHARED — sourced by both shells
│   │   │   ├── bootstrap.sh   # path resolution, source-once, DOTFILES_SHELL
│   │   │   ├── platform.sh    # is_macos / is_linux (cached)
│   │   │   ├── xdg.sh
│   │   │   ├── path.sh
│   │   │   ├── environment.sh
│   │   │   ├── privacy.sh     # feature flags
│   │   │   ├── history.sh
│   │   │   ├── aliases.sh
│   │   │   ├── functions.sh
│   │   │   ├── ssh-agent.sh
│   │   │   ├── profile.sh     # login profile (brew, agents, lang tools)
│   │   │   ├── login.sh       # post-interactive login + UI helpers
│   │   │   ├── logout.sh      # session cleanup
│   │   │   └── tools.sh       # shared tool env (fzf defaults, nvm stub, …)
│   │   ├── bash/              # Bash compatibility layer only
│   │   │   ├── .bash_env .bash_profile .bashrc .bash_login .bash_logout
│   │   │   └── modules/       # options, completion, keybindings, prompt, tools
│   │   └── zsh/               # Zsh compatibility layer only
│   │       ├── .zshenv .zprofile .zshrc .zlogin .zlogout
│   │       └── modules/       # options, history, completion, plugins, prompt, keybindings, tools
│   ├── terminal/              # local templates, vimrc, iterm themes
│   └── editor/                # nvim, alacritty, tmux, zellij, …
└── docs/
```

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

## Compatibility layer

Shell-specific modules exist **only** where POSIX/shared code cannot express the feature:

| Concern        | Shared (`lib/`)     | Bash module              | Zsh module                |
|----------------|---------------------|--------------------------|---------------------------|
| Options        | —                   | `shopt`                  | `setopt`                  |
| Completion     | —                   | bash-completion          | `compinit` / zstyle       |
| Key bindings   | —                   | readline `bind`          | ZLE `bindkey`             |
| Prompt         | —                   | `PS1` + git funcs        | `PROMPT` + `vcs_info`     |
| Plugins        | —                   | —                        | OMZ / autosuggestions     |
| Tool hooks     | fzf defaults, nvm   | `zoxide init bash`       | `zoxide init zsh`         |
| Profile/login  | **all shared**      | thin entry points        | thin entry points         |

`DOTFILES_SHELL` is set in `bootstrap.sh` (`bash` | `zsh`) so shared code can branch only when necessary (e.g. `mise activate`).

## Installer responsibilities

`scripts/install.sh` is the **only** place that decides:

1. Which shell to configure (`auto` | `zsh` | `bash` | `both`)
2. Which entry-point files to symlink
3. Whether syntax validation can run
4. Whether local templates should be created

It does **not** embed shell runtime logic. Runtime code never re-decides install layout.

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

- `~/.zshrc.local` / `~/.bashrc.local`
- `~/.zprofile.local` / `~/.bash_profile.local`
- `~/.zshenv.local` / `~/.bash_env.local`
- `~/.gitconfig.local`

Templates live under `config/terminal/`.

## Performance notes

- Platform flags are computed once in `platform.sh`.
- Login banners and docker probes are off by default.
- NVM and mise are lazy stubs until first invocation.
- Zsh reuses `.zcompdump` for 24h (`compinit -C`).
- PATH is built in a single pass with duplicate checks.
- Shared modules use source-once markers to avoid re-work.

## Extending

**New shared alias/function:** edit `lib/aliases.sh` or `lib/functions.sh`.

**New shell-specific option:** edit `bash/modules/options.bash` or `zsh/modules/options.zsh`.

**New OS support:** extend `platform.sh` and the few `is_macos`/`is_linux` call sites; prefer capability detection (`command -v`, file tests) over OS switches.

**New shell (e.g. fish):** not targeted — would need a separate runtime model. Prefer adding another thin entry directory that still sources `lib/` where possible.
