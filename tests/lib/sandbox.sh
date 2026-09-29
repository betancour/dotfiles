# sandbox.sh — temporary home for one shell. Nothing here writes to the real $HOME.

sb_destroy() {
    if [ -n "${SB_ROOT:-}" ] && [ -d "$SB_ROOT" ]; then
        rm -rf "$SB_ROOT"
    fi
    SB_ROOT=
    SB_HOME=
}

sb_link() {
    # $1 real path  $2 sandbox path
    if [ -e "$1" ] || [ -L "$1" ]; then
        mkdir -p "$(dirname "$2")"
        ln -s "$1" "$2"
    fi
}

sb_link_bins() {
    local src=$1 dest=$2 name
    [ -d "$src" ] || return 0
    mkdir -p "$dest"
    for src in "$src"/*; do
        [ -e "$src" ] || [ -L "$src" ] || continue
        name=$(basename "$src")
        case $name in
            launchctl|systemctl) continue ;;
        esac
        ln -s "$src" "$dest/$name"
    done
}

sb_create() {
    sb_destroy
    SB_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
    SB_HOME=$SB_ROOT/home
    SB_TMP=$SB_ROOT/tmp
    SB_CWD=$SB_ROOT/cwd
    SB_LOG=$SB_ROOT/launchctl.log
    local old_umask
    old_umask=$(umask)
    umask 077
    mkdir -p \
        "$SB_HOME/.local/bin" \
        "$SB_HOME/.cache" \
        "$SB_HOME/.local/state/shell" \
        "$SB_HOME/.local/share" \
        "$SB_HOME/.config" \
        "$SB_TMP" \
        "$SB_CWD"
    : > "$SB_LOG"
    # Today's stamp, so a top-level TTY does not run `brew outdated`.
    date +%Y%m%d > "$SB_HOME/.cache/shell_update_check"

    ln -s "$DF_ROOT" "$SB_HOME/.dotfiles"

    ln -s "$DF_ROOT/shell/zsh/.zshenv" "$SB_HOME/.zshenv"
    ln -s "$DF_ROOT/shell/zsh/.zprofile" "$SB_HOME/.zprofile"
    ln -s "$DF_ROOT/shell/zsh/.zshrc" "$SB_HOME/.zshrc"
    ln -s "$DF_ROOT/shell/zsh/.zlogin" "$SB_HOME/.zlogin"
    ln -s "$DF_ROOT/shell/zsh/.zlogout" "$SB_HOME/.zlogout"
    ln -s "$DF_ROOT/shell/.zaliases" "$SB_HOME/.zaliases"
    ln -s "$DF_ROOT/shell/.zfunctions" "$SB_HOME/.zfunctions"

    ln -s "$DF_ROOT/shell/bash/.bash_env" "$SB_HOME/.bash_env"
    ln -s "$DF_ROOT/shell/bash/.bash_profile" "$SB_HOME/.bash_profile"
    ln -s "$DF_ROOT/shell/bash/.bashrc" "$SB_HOME/.bashrc"
    ln -s "$DF_ROOT/shell/bash/.bash_login" "$SB_HOME/.bash_login"
    ln -s "$DF_ROOT/shell/bash/.bash_logout" "$SB_HOME/.bash_logout"

    ln -s "$DF_ROOT/shell/sh/.profile" "$SB_HOME/.profile"

    ln -s "$DF_ROOT/config/starship/starship.toml" "$SB_HOME/.config/starship.toml"
    ln -s "$DF_ROOT/config/eza" "$SB_HOME/.config/eza"

    sb_link "$HOME/.java-tools" "$SB_HOME/.java-tools"
    sb_link "$HOME/.bun" "$SB_HOME/.bun"
    sb_link "$HOME/.cargo" "$SB_HOME/.cargo"
    sb_link "$HOME/.npm-global" "$SB_HOME/.npm-global"
    sb_link "$HOME/.dotnet" "$SB_HOME/.dotnet"
    sb_link "$HOME/.yarn" "$SB_HOME/.yarn"
    sb_link "$HOME/go/bin" "$SB_HOME/go/bin"
    sb_link "$HOME/bin" "$SB_HOME/bin"
    sb_link "$HOME/.oh-my-zsh" "$SB_HOME/.oh-my-zsh"
    sb_link "$HOME/.local/share/mise" "$SB_HOME/.local/share/mise"
    if [ -d "$HOME/.grok/bin" ]; then
        mkdir -p "$SB_HOME/.grok"
        ln -s "$HOME/.grok/bin" "$SB_HOME/.grok/bin"
    fi
    sb_link_bins "$HOME/.local/bin" "$SB_HOME/.local/bin"

    # ~/.local/bin is first on PATH, so these stand-ins win over the system tools.
    ln -sf "$DF_ROOT/tests/fixtures/bin/launchctl" "$SB_HOME/.local/bin/launchctl"
    ln -sf "$DF_ROOT/tests/fixtures/bin/systemctl" "$SB_HOME/.local/bin/systemctl"
    chmod +x "$DF_ROOT/tests/fixtures/bin/launchctl" \
        "$DF_ROOT/tests/fixtures/bin/systemctl" \
        "$DF_ROOT/tests/fixtures/bin/fail-tool" 2>/dev/null || true

    umask "$old_umask"
    sb_env_defaults
}

sb_env_defaults() {
    SB_SHLVL=0
    SB_TERM=xterm-256color
    SB_COLORTERM_SET=0
    SB_COLORTERM=
    SB_TERM_PROGRAM=
    SB_BASH_ENV=
    SB_EXTRA=
    SB_SHELL_BIN=$DF_ZSH
}

sb_write_env() {
    SB_ENV=$SB_ROOT/env
    {
        printf 'HOME=%s\n' "$SB_HOME"
        printf 'TMPDIR=%s\n' "$SB_TMP"
        printf 'PATH=/usr/bin:/bin:/usr/sbin:/sbin\n'
        printf 'LANG=en_US.UTF-8\n'
        printf 'LC_CTYPE=en_US.UTF-8\n'
        printf 'USER=%s\n' "$SB_USER"
        printf 'LOGNAME=%s\n' "$SB_USER"
        printf 'SHELL=%s\n' "$SB_SHELL_BIN"
        printf 'UID=%s\n' "$SB_UID"
        printf 'DOTFILES_TEST_LAUNCHCTL_LOG=%s\n' "$SB_LOG"
        printf 'DOTFILES_TEST_UMASK=022\n'
        printf 'SHLVL=%s\n' "$SB_SHLVL"
        printf 'TERM=%s\n' "$SB_TERM"
        if [ "$SB_COLORTERM_SET" = 1 ]; then
            printf 'COLORTERM=%s\n' "$SB_COLORTERM"
        fi
        if [ -n "$SB_TERM_PROGRAM" ]; then
            printf 'TERM_PROGRAM=%s\n' "$SB_TERM_PROGRAM"
        fi
        if [ -n "$SB_BASH_ENV" ]; then
            printf 'BASH_ENV=%s\n' "$SB_BASH_ENV"
        fi
        if [ -n "${SSH_AUTH_SOCK:-}" ]; then
            printf 'SSH_AUTH_SOCK=%s\n' "$SSH_AUTH_SOCK"
        fi
        if [ -n "$SB_EXTRA" ]; then
            printf '%s\n' "$SB_EXTRA"
        fi
    } > "$SB_ENV"
}
