# baseline.sh — render observed contracts and publish them only on request.

df_env_keys() {
    cat <<'EOF'
BAT_CONFIG_PATH
BUN_INSTALL
DOTFILES_DIR
DOTFILES_SHELL
EDITOR
FZF_DEFAULT_OPTS
HISTFILE
HISTSIZE
HOMEBREW_CELLAR
HOMEBREW_PREFIX
JAVA_HOME
LANG
LC_ALL
LC_CTYPE
NVM_DIR
PAGER
RIPGREP_CONFIG_PATH
SAVEHIST
VISUAL
XDG_CACHE_HOME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
cmd_brew
cmd_git
cmd_java
cmd_launchctl
cmd_node
cmd_nvim
cmd_starship
cmd_zoxide
EOF
}

df_tilde_value() {
    # $1 capture name, value on stdin
    local home
    home=$(cat "$DF_WORK/cap/$1.home")
    sed -e "s|$home|~|g" -e "s|$HOME|~|g"
}

df_render_env() {
    local cap=$1 dest=$2 key val
    : > "$DF_WORK/env.render"
    for key in $(df_env_keys); do
        val=$(df_probe "$cap" "$key" | df_tilde_value "$cap")
        printf '%s=%s\n' "$key" "$val" >> "$DF_WORK/env.render"
    done
    LC_ALL=C sort -o "$dest" "$DF_WORK/env.render"
}

df_render_block() {
    local cap=$1 begin=$2 end=$3 dest=$4 home
    home=$(cat "$DF_WORK/cap/$cap.home")
    df_probe_block "$cap" "$begin" "$end" "$dest" "$home"
}

df_render_startup() {
    local cap=$1 dest=$2 key val
    : > "$DF_WORK/startup.render"
    for key in umask histfile globdots nullglob extendedglob beep sharehistory; do
        if [ "$key" = histfile ]; then
            val=$(df_probe "$cap" HISTFILE | df_tilde_value "$cap")
        else
            val=$(df_probe "$cap" "$key")
        fi
        printf '%s=%s\n' "$key" "$val" >> "$DF_WORK/startup.render"
    done
    LC_ALL=C sort -o "$dest" "$DF_WORK/startup.render"
}

df_render_banner() {
    local kind=$1 cap=$2 dest=$3
    python3 "$DF_LIB/banner.py" "$kind" "$DF_WORK/cap/$cap.out" > "$dest" 2>"$dest.err"
    local rc=$?
    if [ -s "$dest.err" ]; then
        cat "$dest.err" >> "$dest"
    fi
    rm -f "$dest.err"
    return "$rc"
}

df_render_metadata() {
    {
        printf 'generated=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'os=%s\n' "$(uname -s)"
        printf 'arch=%s\n' "$(uname -m)"
        printf 'zsh=%s\n' "$("$DF_ZSH" --version 2>&1)"
        printf 'bash=%s\n' "$("$DF_BASH" --version | head -n 1)"
        printf 'iterations=%s\n' "$DF_ITERS"
        printf 'perf_ratio=%s\n' "$DF_RATIO"
        printf 'perf_slack_ms=%s\n' "$DF_SLACK"
        printf 'term_profile=xterm-256color\n'
        printf 'tty_colorterm=truecolor\n'
        printf 'note=timings and command paths are this machine; update the baseline explicitly after an intentional change\n'
    } > "$1"
}

df_secret_scan() {
    local hit
    hit=$(grep -E -n -I \
        -e 'BEGIN [A-Z ]*PRIVATE KEY' \
        -e 'AKIA[0-9A-Z]{16}' \
        -e 'ghp_[A-Za-z0-9]' \
        -e 'github_pat_' \
        -e 'SSH_AUTH_SOCK' \
        -e 'aws_secret' \
        -e 'api[_-]?key' \
        "$1"/* 2>/dev/null || true)
    printf '%s\n' "$hit"
}

df_publish_baselines() {
    local draft=$DF_WORK/draft ok=1 hit
    rm -rf "$draft"
    mkdir -p "$draft"
    df_section_begin "Baseline recorded"
    df_render_env zsh_i "$draft/zsh.env"
    df_render_env bash_i "$draft/bash.env"
    df_render_block zsh_i DF_ALIASES_BEGIN DF_ALIASES_END "$draft/zsh.aliases"
    df_render_block bash_i DF_ALIASES_BEGIN DF_ALIASES_END "$draft/bash.aliases"
    df_render_block zsh_i DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$draft/zsh.functions"
    df_render_block bash_i DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$draft/bash.functions"
    df_render_startup zsh_i "$draft/zsh.startup"
    df_render_startup bash_i "$draft/bash.startup"
    if ! df_render_banner 24 zsh_i_tty "$draft/banner.24"; then
        df_fail "24-bit ribbon could not be recorded from a live terminal:
$(cat "$draft/banner.24")"
        rm -f "$draft/banner.24"
        ok=0
    fi
    if ! df_render_banner 256 zsh_256 "$draft/banner.256"; then
        df_fail "256-color ribbon could not be recorded:
$(cat "$draft/banner.256")"
        rm -f "$draft/banner.256"
        ok=0
    fi
    if ! df_render_banner 16 zsh_16 "$draft/banner.16"; then
        df_fail "16-color ribbon could not be recorded:
$(cat "$draft/banner.16")"
        rm -f "$draft/banner.16"
        ok=0
    fi
    df_render_metadata "$draft/metadata"
    hit=$(df_secret_scan "$draft")
    if [ -n "$hit" ]; then
        df_fail "Refusing to store a baseline that looks like a secret:
$hit"
        ok=0
    fi
    if [ "$ok" = 1 ]; then
        mkdir -p "$DF_BASE"
        cp -f "$draft"/* "$DF_BASE"/
    else
        df_fail "Baseline was not published."
    fi
    df_section_end
}

df_diff_file() {
    if ! diff -u "$1" "$2" > "$DF_WORK/diff.out"; then
        df_fail "$3
$(head -n 80 "$DF_WORK/diff.out")"
        return 1
    fi
    return 0
}

df_compare_rendered() {
    # $1 baseline filename  $2 renderer words are handled by the caller via dest
    local base=$DF_BASE/$1 live=$2 label=$3
    df_need_file "$base" || return 1
    df_diff_file "$base" "$live" "$label"
}
