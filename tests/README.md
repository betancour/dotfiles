# Dotfiles test suite

The test suite is the behavioral contract for the dotfiles. Any future configuration change must pass the suite unless the corresponding contract is intentionally changed and the baseline is explicitly updated.

A configuration change is not finished when a shell happens to start. It is finished when `./tests/run.sh` passes.

## Run

From the repository root:

```sh
./tests/run.sh
```

`make test` does the same thing.

The suite launches real `zsh` and `bash` processes. It does not decide that a file is correct by reading it. Syntax checks are only the first step.

```text
change the dotfiles
        ↓
./tests/run.sh
        ↓
fix a real failure
        ↓
./tests/run.sh
        ↓
review the diff
        ↓
commit
```

Normal runs never rewrite recorded baselines.

## What is covered

Each line in the report is one area. A failure includes the reason and, where it helps, the expected and actual values.

| Area | What a pass means |
|------|-------------------|
| Syntax | Shared libraries parse under Bash 3.2 and Bash 5, Zsh files parse under Zsh, POSIX entry points parse |
| Startup | `zsh -c`, `zsh -i`, `zsh -l -i`, `bash -c`, `bash -c` with `BASH_ENV`, `bash -i`, `bash --login -i`, and login `sh` exit 0 |
| Stderr | A pipe has empty stderr. A terminal is scanned for error text. Stderr is not discarded |
| PATH | No duplicates, no empty components, `~/.local/bin` first, Homebrew before `/usr/bin` when that prefix exists, JDK and Node kegs before `/usr/bin`, mise shims after Homebrew |
| Environment | `LANG`, unset `LC_ALL`, history size, XDG directories, `DOTFILES_DIR` pointing at this repository. `HOMEBREW_PREFIX` is exported by the login profile and stays unset otherwise |
| Aliases and functions | Interactive shells only. `mkcd`, `up`, and `help` run. `wget` with no URL returns 127 when the real binary is absent. `reload` is not executed |
| Tools | Completion, Starship, fzf, and syntax highlighting follow tty rules. Starship 1.26 exposes `prompt_starship_precmd`; an older `starship_precmd` name still counts. `GPG_TTY` is set only on a terminal |
| Banner | Top-level interactive tty only. Truecolor, 256-color, and 16-color. Nested shells and scripts print nothing |
| Performance | Median of repeated launches against the recorded baseline |
| Isolation | The real launchctl stamp, completion dump, and gitconfig are unchanged |

Bash is not the login shell on this machine. The suite still symlinks the repository's Bash entry points into a temporary home and starts that Bash. Zsh entry points are the ones installed in the real home.

Login `sh` reads `~/.profile`. `sh -c` does not.

## Baseline

`./tests/run.sh --update-baseline` records what the current shells actually do, then runs the suite against that recording. It is the only command that writes `tests/baseline/`.

Recorded files:

| File | Contents |
|------|----------|
| `zsh.env`, `bash.env` | Whitelisted variables and resolved commands, with home paths rewritten to `~` |
| `zsh.aliases`, `bash.aliases` | Interactive alias tables |
| `zsh.functions`, `bash.functions` | Interactive function names, including conditional ones such as `wget` |
| `zsh.startup`, `bash.startup` | Observed umask, history file, and shell options |
| `banner.24`, `banner.256`, `banner.16` | Ribbon color cells from a live terminal |
| `timing.env` | Min, median, and max milliseconds |
| `metadata` | OS, architecture, shell versions, iteration count. Not compared |

Do not put secrets in the baseline. The publisher refuses files that look like private keys, cloud tokens, or `SSH_AUTH_SOCK`. `GPG_TTY` is stored only as `set` or `unset`.

These are not frozen: hostname, working directory, date, git branch, terminal size, and tool version strings. Command paths are recorded because a silent change of which `java` or `node` runs is a behavior change. After an intentional toolchain upgrade, review the diff and update the baseline on purpose.

Startup success, empty unexpected stderr, the banner's hue order, PATH rules, and the interactive umask are checked in the suite itself. Updating the baseline does not waive those.

The environment snapshot is the non-login interactive shell, so `HOMEBREW_PREFIX` and `HOMEBREW_CELLAR` are recorded as unset there. Login shells are checked separately and must export the prefix that `dotfiles_brew_env` selects.

Interactive Bash with no controlling terminal writes two lines of its own before any rc file:

```text
bash: cannot set terminal process group (PID): Inappropriate ioctl for device
bash: no job control in this shell
```

The pid varies. Those two lines, and nothing else, are accepted on `bash -i` and `bash --login -i` pipes. The same lines on a real terminal are a failure. Zsh pipes, non-interactive Bash, and `BASH_ENV` still require empty stderr.

## Performance

Each sample is a real process. The default is 10 iterations after one warmup in the same temporary home, so completion and Starship caches are warm. The warmup is not part of the median.

```text
iterations: 10
minimum:    ...
median:     ...
maximum:    ...
```

A sample fails only when the new median is greater than both:

- baseline median × `DOTFILES_TEST_PERF_RATIO` (default `1.5`)
- baseline median + `DOTFILES_TEST_PERF_SLACK_MS` (default `25`)

That is `max(baseline × ratio, baseline + slack)`. A few milliseconds of noise stays under the slack. A 50% slowdown does not.

Timed commands:

| Key | Command | Notes |
|-----|---------|-------|
| `zsh_i_pipe` | `zsh -i -c exit` | No terminal, no ribbon |
| `zsh_i_tty` | `zsh -i -c exit` | Top-level terminal, truecolor ribbon |
| `zsh_l_tty` | `zsh -l -i -c exit` | Includes `.zlogout`. This is process time, not time-to-prompt |
| `zsh_c_pipe` | `zsh -c exit` | Environment only |
| `bash_i_pipe` | `bash -i -c exit` | |
| `bash_l_pipe` | `bash --login -i -c exit` | |

The daily Homebrew check is not in the sample. The sandbox seeds today's update stamp. The first login in a fresh home would publish `launchctl` settings; measured logins are the steady state after that warmup.

Override the knobs without editing the suite:

```sh
DOTFILES_TEST_ITERS=10 \
DOTFILES_TEST_PERF_RATIO=1.5 \
DOTFILES_TEST_PERF_SLACK_MS=25 \
./tests/run.sh
```

## Color banner

The ribbon is part of the contract, not decoration. The check reads the ribbon line only: a line of color whose visible text is empty, so the prompt and the logout farewell cannot change the result.

It must:

- appear for a top-level interactive terminal, login and non-login, Zsh and Bash
- stay absent for scripts, pipes, nested shells (`SHLVL` greater than 1), and non-interactive terminals
- run red, orange, yellow, green, cyan, blue, purple, then a white break, then the same sequence, then a near-black close
- end that line with an SGR reset (`ESC [ 0 m`)

Truecolor cells are compared to `banner.24`. A refactor that prints the same cells still passes. A different hue fails even if the baseline is rewritten, because the shape check is separate from the snapshot. `COLORTERM=truecolor` selects 24-bit. `TERM=xterm-256color` with no color hint selects 256-color. `TERM=xterm` selects 16-color. `TERM_PROGRAM=iTerm.app` selects 24-bit even when `TERM` is `xterm`.

The suite sets `TERM` itself. It does not inherit a dumb terminal from a CI runner or an agent.

## Platform behavior

macOS expects Homebrew at `/opt/homebrew` or `/usr/local` when that `brew` binary exists, and expects the sandbox `launchctl` stand-in to be called once per new login environment. Linux expects the linuxbrew prefix when that tree exists, and does not fail because `/opt/homebrew` is absent. A missing optional command (`kubectl`, `nvm`, `pyenv`, `fnm`, `wget`) must not fail startup.

Homebrew cannot be hidden on a machine where `/opt/homebrew/bin` exists: `path.sh` adds that directory because it is there, not because it was already on `PATH`. The suite checks the recoverable case instead: a minimal incoming `PATH` still exits 0 and is rebuilt. A separate sandbox puts failing `starship` and `zoxide` binaries ahead of the real ones. Startup must still exit 0, print no stderr, and leave `mkcd` working.

## Isolation

Every shell runs with a temporary `HOME`. The repository is linked as `~/.dotfiles`, and the shell entry points are symlinks into it, so startup resolves the real tree. Toolchain directories that contain no credentials are linked read-only (Java tools, Bun, Cargo, npm, .NET, Yarn, Oh My Zsh, mise, `~/.grok/bin` only). These are not linked: `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config` as a whole, `~/.grok/auth.json`, Neovim's config, and `~/.zshrc.local`.

`~/.local/bin/launchctl` and `systemctl` are stand-ins. They append their arguments to a log and exit 0. They never call the real user domain.

The child starts with `PATH=/usr/bin:/bin:/usr/sbin:/sbin` and umask `022`. Interactive shells must change that umask to `077`. The inherited `SSH_AUTH_SOCK` is passed through so startup does not create an agent. Nothing else from the parent environment is passed. `LC_ALL` is left unset on purpose.

The suite does not read or checksum the live `~/.zsh_history`. It does check that the shell's `HISTFILE` is inside the sandbox.

## Add a test

1. Put the behavior in `tests/lib/cases.sh` if it is a shell contract, or extend `tests/lib/probe.sh` if the shell under test has to report a new field.
2. Prefer a behavior (exit status, resolved command, tty gate) over a source-line match.
3. Keep one pass/fail line per area unless a new area is genuinely separate.
4. Run `./tests/run.sh`. If the failure is the new assertion seeing the current behavior, the assertion is ahead of the contract. If the assertion matches the intended behavior, fix the dotfiles.
5. Run `./tests/run.sh --update-baseline` only after the new behavior is intentional, then review `tests/baseline/`.

Do not weaken an assertion to make a bad change pass. Decide whether the configuration is wrong, the test is wrong, or the behavior was changed on purpose.

## Git hook

The hook is not installed automatically.

```sh
ln -sfn ../../tests/hooks/pre-commit .git/hooks/pre-commit
```

Remove it with `rm .git/hooks/pre-commit`. The hook runs the full suite and will block a commit when the contract fails.

## Breaking change

A breaking change is one that makes `./tests/run.sh` fail. Typical causes:

- startup exits non-zero or writes unexpected stderr
- an interactive alias, function, or history file moves
- PATH order, duplicates, or a missing required directory
- the ribbon runs in a script, disappears from a top-level terminal, or changes hue
- interactive startup gets slower than the ratio and the slack allow
- a shell under test starts writing outside the sandbox

Fix the dotfiles, or change the contract and refresh the baseline in the same commit so the diff shows the decision.
