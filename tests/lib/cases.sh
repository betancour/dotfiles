# cases.sh — behavioral contract. Assertions describe observed shell behavior.

DF_REQUIRED_FNS="n mkcd up cdf extract findfile finddir fsize backup sysinfo myip localip gitcp gitbr gitlog dpshow dclean genpass weather install-java-tools update-java-tools java-tools-status help reload"

df_require_probe() {
    if ! grep -q '^DF_PROBE_END$' "$DF_WORK/cap/$1.out" 2>/dev/null; then
        df_fail "No probe block from $1 (exit $(df_meta_rc "$1")).
stdout:
$(head -n 30 "$DF_WORK/cap/$1.out" 2>/dev/null)
stderr:
$(head -n 30 "$DF_WORK/cap/$1.err" 2>/dev/null)"
        return 1
    fi
    return 0
}

df_pipe_ok() {
    local rc
    rc=$(df_meta_rc "$1")
    df_expect "$rc" 0 "$2 exit status"
    df_fail_stderr "$DF_WORK/cap/$1.err" "$2"
}

# Interactive bash with no terminal prints these two lines from bash itself,
# inside initialize_job_control, before any rc file. The pid changes. A real
# terminal must not print them, and any other stderr is still a failure.
df_bash_pipe_ok() {
    local rc rest
    rc=$(df_meta_rc "$1")
    df_expect "$rc" 0 "$2 exit status"
    rest=$(grep -v -E '^bash: cannot set terminal process group \([0-9]+\): Inappropriate ioctl for device$' \
        "$DF_WORK/cap/$1.err" 2>/dev/null \
        | grep -v -E '^bash: no job control in this shell$' \
        || true)
    if [ -n "$rest" ]; then
        df_fail "Unexpected stderr from $2:
$(printf '%s\n' "$rest" | sed 's/^/  /')"
        return 1
    fi
    return 0
}

df_bash_tty_job_control() {
    if grep -a -q 'no job control in this shell' "$DF_WORK/cap/$1.out" 2>/dev/null; then
        df_fail "$2 reported no job control on a terminal"
        return 1
    fi
    return 0
}

df_pty_ok() {
    df_expect "$(df_meta_rc "$1")" 0 "$2 exit status"
    df_deny_output "$DF_WORK/cap/$1.out" "$2"
}

df_banner_absent() {
    local err
    err=$(python3 "$DF_LIB/banner.py" absent "$DF_WORK/cap/$1.out" 2>&1) || {
        df_fail "$2
$err"
        return 1
    }
    return 0
}

df_banner_match() {
    local err
    if ! df_need_file "$3"; then
        return 1
    fi
    err=$(python3 "$DF_LIB/banner.py" "$1" "$DF_WORK/cap/$2.out" "$3" 2>&1) || {
        df_fail "$4
$err"
        return 1
    }
    return 0
}

df_line_of() {
    local n
    n=$(grep -n -x -F "$1" "$2" | head -n 1 | cut -d: -f1)
    if [ -z "$n" ]; then
        return 1
    fi
    printf '%s\n' "$n"
}

df_assert_path() {
    local path=$1 label=$2 home=$3 cap=$4
    local comps=$DF_WORK/pathcomps usr bin brew first dups jh ji node mi shims keg
    printf '%s\n' "$path" | tr ':' '\n' > "$comps"
    if grep -qx '' "$comps"; then
        df_fail "$label: PATH contains an empty component"
    fi
    if grep -qx '\.' "$comps"; then
        df_fail "$label: PATH contains '.'"
    fi
    dups=$(LC_ALL=C sort "$comps" | uniq -d | sed '/^$/d')
    if [ -n "$dups" ]; then
        df_fail "$label: duplicate PATH entries:
$dups"
    fi
    usr=$(df_line_of /usr/bin "$comps" || true)
    bin=$(df_line_of /bin "$comps" || true)
    [ -n "$usr" ] || df_fail "$label: /usr/bin is not on PATH"
    [ -n "$bin" ] || df_fail "$label: /bin is not on PATH"
    if [ -d "$home/.local/bin" ]; then
        first=$(head -n 1 "$comps")
        if [ "$first" != "$home/.local/bin" ]; then
            df_fail "$label: ~/.local/bin is not the first PATH entry" "$home/.local/bin" "$first"
        fi
    fi
    if [ "$home" != "$HOME" ] && grep -qx -F "$HOME/.local/bin" "$comps"; then
        df_fail "$label: PATH contains the real ~/.local/bin"
    fi
    brew=
    if [ -d /opt/homebrew/bin ]; then
        brew=$(df_line_of /opt/homebrew/bin "$comps" || true)
        if [ -z "$brew" ]; then
            df_fail "$label: /opt/homebrew/bin is not on PATH"
        elif [ -n "$usr" ] && [ "$brew" -ge "$usr" ]; then
            df_fail "$label: Homebrew bin is not before /usr/bin" "before line $usr" "line $brew"
        fi
    fi
    if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
        local lb
        lb=$(df_line_of /home/linuxbrew/.linuxbrew/bin "$comps" || true)
        if [ -z "$lb" ]; then
            df_fail "$label: linuxbrew bin is not on PATH"
        elif [ -n "$usr" ] && [ "$lb" -ge "$usr" ]; then
            df_fail "$label: linuxbrew bin is not before /usr/bin"
        fi
        [ -n "$brew" ] || brew=$lb
    fi
    jh=$(df_probe "$cap" JAVA_HOME)
    if [ -n "$jh" ] && [ "$jh" != unset ] && [ -d "$jh/bin" ]; then
        ji=$(df_line_of "$jh/bin" "$comps" || true)
        if [ -z "$ji" ]; then
            df_fail "$label: JAVA_HOME/bin is not on PATH" "$jh/bin" "absent"
        elif [ -n "$usr" ] && [ "$ji" -ge "$usr" ]; then
            df_fail "$label: JAVA_HOME/bin is not before /usr/bin"
        fi
    fi
    node=
    for keg in \
        /opt/homebrew/opt/node/bin \
        /opt/homebrew/opt/node@24/bin \
        /opt/homebrew/opt/node@22/bin \
        /opt/homebrew/opt/node@20/bin \
        /usr/local/opt/node/bin
    do
        if [ -d "$keg" ]; then
            node=$keg
            break
        fi
    done
    if [ -n "$node" ]; then
        local ni
        ni=$(df_line_of "$node" "$comps" || true)
        if [ -z "$ni" ]; then
            df_fail "$label: node keg is not on PATH" "$node" "absent"
        elif [ -n "$usr" ] && [ "$ni" -ge "$usr" ]; then
            df_fail "$label: node keg is not before /usr/bin" "$node before /usr/bin" "line $ni"
        fi
    fi
    shims=$home/.local/share/mise/shims
    if [ -d "$shims" ]; then
        mi=$(df_line_of "$shims" "$comps" || true)
        if [ -z "$mi" ]; then
            df_fail "$label: mise shims exist but are not on PATH"
        elif [ -n "$brew" ] && [ "$mi" -le "$brew" ]; then
            df_fail "$label: mise shims are not after Homebrew" "after line $brew" "line $mi"
        fi
    fi
}

df_brew_prefix_expect() {
    if [ -x /opt/homebrew/bin/brew ]; then
        printf '%s\n' /opt/homebrew
    elif [ -x /usr/local/bin/brew ]; then
        printf '%s\n' /usr/local
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        printf '%s\n' "$HOME/.linuxbrew"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        printf '%s\n' /home/linuxbrew/.linuxbrew
    else
        printf '%s\n' unset
    fi
}

df_highlight_available() {
    [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \
        || [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \
        || [ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
        || [ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]
}

df_fzf_bindings() {
    [ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] \
        || [ -f /usr/share/fzf/key-bindings.zsh ] \
        || [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] \
        || [ -f "$HOME/.fzf.zsh" ]
}

df_section_repository() {
    local f
    df_section_begin "Repository structure"
    for f in \
        shell/zsh/.zshenv shell/zsh/.zprofile shell/zsh/.zshrc shell/zsh/.zlogin shell/zsh/.zlogout \
        shell/bash/.bashrc shell/bash/.bash_profile shell/bash/.bash_env shell/bash/.bash_login \
        shell/sh/.profile shell/lib/login.sh shell/lib/path.sh shell/lib/environment.sh \
        tests/run.sh tests/README.md tests/lib/probe.sh tests/lib/harness.sh tests/lib/sandbox.sh \
        tests/lib/invoke.sh tests/lib/baseline.sh tests/lib/cases.sh tests/lib/pty_run.py \
        tests/lib/banner.py tests/fixtures/bin/launchctl tests/fixtures/bin/systemctl \
        tests/fixtures/bin/fail-tool tests/hooks/pre-commit
    do
        if [ ! -f "$DF_ROOT/$f" ]; then
            df_fail "Missing $f"
        fi
    done
    df_section_end
}

df_syntax_one() {
    local bin=$1 file=$2
    if ! "$bin" -n "$file" 2>"$DF_WORK/syn.err"; then
        df_fail "$bin -n $file
$(cat "$DF_WORK/syn.err")"
    fi
}

df_section_syntax_bash() {
    local f
    df_section_begin "Bash syntax"
    for f in "$DF_ROOT"/shell/lib/*.sh "$DF_ROOT"/shell/bash/.bash_* \
        "$DF_ROOT"/shell/bash/modules/*.bash \
        "$DF_ROOT"/tests/run.sh "$DF_ROOT"/tests/lib/*.sh "$DF_ROOT"/tests/hooks/pre-commit \
        "$DF_ROOT"/tests/lib/probe.sh
    do
        [ -f "$f" ] || continue
        df_syntax_one "$DF_BASH" "$f"
        if [ -x /bin/bash ] && [ "/bin/bash" != "$DF_BASH" ]; then
            df_syntax_one /bin/bash "$f"
        fi
    done
    df_section_end
}

df_section_syntax_zsh() {
    local f
    df_section_begin "Zsh syntax"
    for f in "$DF_ROOT"/shell/zsh/.z* "$DF_ROOT"/shell/zsh/modules/*.zsh \
        "$DF_ROOT"/shell/lib/*.sh "$DF_ROOT"/tests/lib/probe.sh
    do
        [ -f "$f" ] || continue
        df_syntax_one "$DF_ZSH" "$f"
    done
    df_section_end
}

df_section_syntax_sh() {
    local f bin
    df_section_begin "POSIX sh syntax"
    for f in "$DF_ROOT"/shell/sh/.profile "$DF_ROOT"/shell/sh/modules/*.sh \
        "$DF_ROOT"/shell/lib/platform.sh "$DF_ROOT"/tests/hooks/pre-commit \
        "$DF_ROOT"/tests/lib/probe.sh
    do
        [ -f "$f" ] || continue
        df_syntax_one "$DF_BASH" "$f"
        if command -v dash >/dev/null 2>&1; then
            df_syntax_one dash "$f"
        fi
    done
    df_section_end
}

df_capture_all() {
    local probe=$DF_LIB/probe.sh
    sb_env_defaults
    SB_SHELL_BIN=$DF_ZSH
    sb_write_env
    df_run pipe "$DF_ZSH" -i -c exit
    df_run pipe "$DF_ZSH" -l -i -c exit
    SB_SHELL_BIN=$DF_BASH
    sb_write_env
    df_run pipe "$DF_BASH" -i -c exit
    df_run pipe "$DF_BASH" --login -i -c exit

    sb_env_defaults
    SB_SHELL_BIN=$DF_ZSH
    df_capture zsh_c pipe "$DF_ZSH" -c ". '$probe'"
    df_capture zsh_i pipe "$DF_ZSH" -i -c ". '$probe'"
    df_capture zsh_l pipe "$DF_ZSH" -l -i -c ". '$probe'"

    SB_COLORTERM_SET=1
    SB_COLORTERM=truecolor
    df_capture zsh_i_tty pty "$DF_ZSH" -i -c ". '$probe'"
    df_capture zsh_l_tty pty "$DF_ZSH" -l -i -c exit
    df_capture zsh_c_tty pty "$DF_ZSH" -c exit
    SB_SHLVL=1
    df_capture zsh_nested pty "$DF_ZSH" -i -c exit
    SB_SHLVL=0
    SB_COLORTERM_SET=0
    SB_COLORTERM=
    df_capture zsh_256 pty "$DF_ZSH" -i -c exit
    SB_TERM=xterm
    df_capture zsh_16 pty "$DF_ZSH" -i -c exit
    SB_TERM_PROGRAM=iTerm.app
    df_capture zsh_iterm pty "$DF_ZSH" -i -c exit
    SB_TERM_PROGRAM=
    SB_TERM=xterm-256color

    SB_EXTRA='LS_COLORS=foo'
    df_capture zsh_ls_c pipe "$DF_ZSH" -c 'printf %s "$LS_COLORS"'
    df_capture zsh_ls_i pipe "$DF_ZSH" -i -c 'printf %s "${LS_COLORS-unset}"'
    SB_EXTRA=

    SB_SHELL_BIN=$DF_BASH
    df_capture bash_c pipe "$DF_BASH" -c ". '$probe'"
    SB_BASH_ENV=$SB_HOME/.bash_env
    df_capture bash_env pipe "$DF_BASH" -c ". '$probe'"
    SB_BASH_ENV=
    df_capture bash_i pipe "$DF_BASH" -i -c ". '$probe'"
    df_capture bash_l pipe "$DF_BASH" --login -i -c ". '$probe'"
    SB_COLORTERM_SET=1
    SB_COLORTERM=truecolor
    df_capture bash_i_tty pty "$DF_BASH" -i -c exit
    df_capture bash_l_tty pty "$DF_BASH" --login -i -c exit
    SB_COLORTERM_SET=0
    df_capture bash_c_tty pty "$DF_BASH" -c exit

    SB_SHELL_BIN=$DF_SH
    sb_env_defaults
    SB_SHELL_BIN=$DF_SH
    df_capture sh_c pipe "$DF_SH" -c ". '$probe'"
    df_capture sh_l pipe "$DF_SH" -l -c ". '$probe'"
    sb_env_defaults
}

df_section_zsh_noninteractive() {
    df_section_begin "Zsh non-interactive startup"
    df_pipe_ok zsh_c "zsh -c"
    df_pty_ok zsh_c_tty "zsh -c (tty)"
    df_require_probe zsh_c || { df_section_end; return; }
    df_expect "$(df_probe zsh_c interactive)" 0 "zsh -c interactive flag"
    df_expect "$(df_probe zsh_c HISTFILE)" unset "zsh -c must not set HISTFILE"
    local um home
    um=$(df_probe zsh_c umask)
    df_umask_plain "$um" || df_fail "zsh -c keeps the caller umask" "ends with 22" "$um"
    home=$(cat "$DF_WORK/cap/zsh_c.home")
    case $(df_probe zsh_c HISTFILE) in
        "$HOME"/.zsh_history) df_fail "zsh -c points HISTFILE at the real history file" ;;
    esac
    df_banner_absent zsh_c "zsh -c"
    df_banner_absent zsh_c_tty "zsh -c on a terminal"
    df_no_esc "$DF_WORK/cap/zsh_c.out" "zsh -c stdout"
    df_no_esc "$DF_WORK/cap/zsh_c_tty.out" "zsh -c tty stdout"
    df_section_end
}

df_section_zsh_interactive() {
    local um home hf
    df_section_begin "Zsh interactive startup"
    df_pipe_ok zsh_i "zsh -i"
    df_pty_ok zsh_i_tty "zsh -i (tty)"
    df_require_probe zsh_i || { df_section_end; return; }
    df_require_probe zsh_i_tty || { df_section_end; return; }
    df_expect "$(df_probe zsh_i interactive)" 1 "zsh -i interactive flag"
    df_expect "$(df_probe zsh_i login)" 0 "zsh -i is not a login shell"
    um=$(df_probe zsh_i umask)
    df_umask_interactive "$um" || df_fail "interactive zsh umask" "ends with 77" "$um"
    home=$(cat "$DF_WORK/cap/zsh_i.home")
    hf=$(df_probe zsh_i HISTFILE)
    df_expect "$hf" "$home/.local/state/zsh/history" "interactive zsh HISTFILE"
    if [ "$hf" = "$HOME/.zsh_history" ]; then
        df_fail "interactive zsh HISTFILE is the real ~/.zsh_history"
    fi
    df_expect "$(df_probe zsh_i globdots)" 0 "NO_GLOB_DOTS"
    df_expect "$(df_probe zsh_i extendedglob)" 1 "EXTENDED_GLOB"
    df_expect "$(df_probe zsh_i nullglob)" 0 "zsh nullglob off"
    df_expect "$(df_probe zsh_i beep)" 0 "NO_BEEP"
    df_expect "$(df_probe zsh_i sharehistory)" 1 "SHARE_HISTORY"
    df_expect "$(df_probe zsh_i prompt_set)" 1 "interactive zsh prompt"
    df_banner_absent zsh_i "zsh -i without a tty"
    df_section_end
}

df_section_zsh_login() {
    local um
    df_section_begin "Zsh login startup"
    df_pipe_ok zsh_l "zsh -l -i"
    df_pty_ok zsh_l_tty "zsh -l -i (tty)"
    df_require_probe zsh_l || { df_section_end; return; }
    df_expect "$(df_probe zsh_l login)" 1 "zsh -l login flag"
    um=$(df_probe zsh_l umask)
    df_umask_interactive "$um" || df_fail "login zsh umask" "ends with 77" "$um"
    df_banner_absent zsh_l "login zsh without a tty"
    df_section_end
}

df_section_bash_noninteractive() {
    local um home
    df_section_begin "Bash non-interactive startup"
    df_pipe_ok bash_c "bash -c"
    df_pipe_ok bash_env "bash -c with BASH_ENV"
    df_pty_ok bash_c_tty "bash -c (tty)"
    df_require_probe bash_c || { df_section_end; return; }
    df_require_probe bash_env || { df_section_end; return; }
    df_expect "$(df_probe bash_c DOTFILES_DIR)" unset "bash -c does not load dotfiles unless BASH_ENV is set"
    df_expect "$(df_probe bash_c path)" "/usr/bin:/bin:/usr/sbin:/sbin" "bash -c keeps the incoming PATH"
    home=$(cat "$DF_WORK/cap/bash_env.home")
    df_expect "$(df_probe bash_env DOTFILES_SHELL)" bash "BASH_ENV loads the dotfiles environment"
    df_expect "$(df_probe bash_env HISTFILE)" "$home/.local/state/bash/history" "BASH_ENV HISTFILE"
    df_expect "$(df_probe bash_env HISTSIZE)" 50000 "BASH_ENV HISTSIZE"
    um=$(df_probe bash_env umask)
    df_umask_plain "$um" || df_fail "BASH_ENV keeps the caller umask" "ends with 22" "$um"
    df_expect "$(df_probe bash_env ls_alias)" "" "BASH_ENV does not define aliases"
    df_banner_absent bash_c "bash -c"
    df_banner_absent bash_env "bash BASH_ENV"
    df_banner_absent bash_c_tty "bash -c on a terminal"
    df_no_esc "$DF_WORK/cap/bash_c.out" "bash -c stdout"
    df_no_esc "$DF_WORK/cap/bash_env.out" "bash BASH_ENV stdout"
    df_section_end
}

df_section_bash_interactive() {
    local um home hf
    df_section_begin "Bash interactive startup"
    df_bash_pipe_ok bash_i "bash -i"
    df_pty_ok bash_i_tty "bash -i (tty)"
    df_bash_tty_job_control bash_i_tty "bash -i"
    df_require_probe bash_i || { df_section_end; return; }
    df_expect "$(df_probe bash_i interactive)" 1 "bash -i interactive flag"
    df_expect "$(df_probe bash_i login)" 0 "bash -i is not a login shell"
    um=$(df_probe bash_i umask)
    df_umask_interactive "$um" || df_fail "interactive bash umask" "ends with 77" "$um"
    home=$(cat "$DF_WORK/cap/bash_i.home")
    hf=$(df_probe bash_i HISTFILE)
    df_expect "$hf" "$home/.local/state/bash/history" "interactive bash HISTFILE"
    if [ "$hf" = "$HOME/.bash_history" ]; then
        df_fail "interactive bash HISTFILE is the real ~/.bash_history"
    fi
    df_expect "$(df_probe bash_i nullglob)" 0 "bash nullglob off"
    df_expect "$(df_probe bash_i globdots)" 0 "bash dotglob off"
    df_expect "$(df_probe bash_i prompt_set)" 1 "interactive bash prompt"
    df_banner_absent bash_i "bash -i without a tty"
    df_section_end
}

df_section_bash_login() {
    local um home hf
    df_section_begin "Bash login startup"
    df_bash_pipe_ok bash_l "bash --login -i"
    df_pty_ok bash_l_tty "bash --login -i (tty)"
    df_bash_tty_job_control bash_l_tty "bash --login -i"
    df_require_probe bash_l || { df_section_end; return; }
    df_expect "$(df_probe bash_l login)" 1 "bash --login login flag"
    um=$(df_probe bash_l umask)
    df_umask_interactive "$um" || df_fail "login bash umask" "ends with 77" "$um"
    home=$(cat "$DF_WORK/cap/bash_l.home")
    hf=$(df_probe bash_l HISTFILE)
    df_expect "$hf" "$home/.local/state/bash/history" "login bash HISTFILE"
    if [ "$hf" = "$HOME/.bash_history" ]; then
        df_fail "login bash HISTFILE is the real ~/.bash_history"
    fi
    df_banner_absent bash_l "login bash without a tty"
    df_section_end
}

df_section_path() {
    local cap home
    df_section_begin "PATH invariants"
    for cap in zsh_c zsh_i zsh_l bash_env bash_i bash_l; do
        df_require_probe "$cap" || continue
        home=$(cat "$DF_WORK/cap/$cap.home")
        df_assert_path "$(df_probe "$cap" path)" "$cap" "$home" "$cap"
    done
    df_section_end
}

df_section_env() {
    local cap home prefix root got live
    df_section_begin "Environment invariants"
    prefix=$(df_brew_prefix_expect)
    root=$(cd -P "$DF_ROOT" && pwd)
    for cap in zsh_c zsh_i zsh_l bash_env bash_i bash_l; do
        df_require_probe "$cap" || continue
        df_expect "$(df_probe "$cap" LANG)" "en_US.UTF-8" "$cap LANG"
        df_expect "$(df_probe "$cap" LC_ALL)" unset "$cap LC_ALL stays unset"
        df_expect "$(df_probe "$cap" HISTSIZE)" 50000 "$cap HISTSIZE"
        df_expect "$(df_probe "$cap" SAVEHIST)" 50000 "$cap SAVEHIST"
        # dotfiles_brew_env runs from the login profile, not from environment.sh.
        case $cap in
            zsh_l|bash_l)
                df_expect "$(df_probe "$cap" HOMEBREW_PREFIX)" "$prefix" "$cap HOMEBREW_PREFIX"
                if [ "$prefix" != unset ]; then
                    df_expect "$(df_probe "$cap" HOMEBREW_CELLAR)" "$prefix/Cellar" "$cap HOMEBREW_CELLAR"
                fi
                ;;
            *)
                df_expect "$(df_probe "$cap" HOMEBREW_PREFIX)" unset "$cap HOMEBREW_PREFIX is set by the login profile"
                df_expect "$(df_probe "$cap" HOMEBREW_CELLAR)" unset "$cap HOMEBREW_CELLAR is set by the login profile"
                ;;
        esac
        got=$(df_probe "$cap" DOTFILES_DIR)
        if [ -d "$got" ]; then
            got=$(cd -P "$got" && pwd)
        fi
        df_expect "$got" "$root" "$cap DOTFILES_DIR"
        home=$(cat "$DF_WORK/cap/$cap.home")
        df_expect "$(df_probe "$cap" XDG_CONFIG_HOME)" "$home/.config" "$cap XDG_CONFIG_HOME"
        df_expect "$(df_probe "$cap" XDG_CACHE_HOME)" "$home/.cache" "$cap XDG_CACHE_HOME"
        df_expect "$(df_probe "$cap" XDG_STATE_HOME)" "$home/.local/state" "$cap XDG_STATE_HOME"
        df_expect "$(df_probe "$cap" XDG_DATA_HOME)" "$home/.local/share" "$cap XDG_DATA_HOME"
    done
    home=$(cat "$DF_WORK/cap/zsh_i.home")
    if [ -x "$home/.local/bin/nvim" ] || [ -x /opt/homebrew/bin/nvim ] || [ -x /usr/local/bin/nvim ]; then
        df_expect "$(df_probe zsh_i EDITOR)" nvim "EDITOR when nvim is installed"
        df_expect "$(df_probe bash_i EDITOR)" nvim "bash EDITOR when nvim is installed"
    fi
    got=$(df_probe zsh_i cmd_git)
    if [ -z "$got" ] || [ "$got" = missing ] || [ ! -x "$got" ]; then
        df_fail "git does not resolve to an executable" "an executable on PATH" "$got"
    fi
    if [ "$prefix" != unset ]; then
        case $(df_probe zsh_i cmd_brew) in
            missing|"") df_fail "brew does not resolve in an interactive zsh" "$prefix/bin/brew" "$(df_probe zsh_i cmd_brew)" ;;
        esac
    fi
    case $(df_probe zsh_i cmd_launchctl) in
        "$home"/.local/bin/launchctl) ;;
        *) df_fail "launchctl must resolve to the sandbox stand-in" "$home/.local/bin/launchctl" "$(df_probe zsh_i cmd_launchctl)" ;;
    esac
    if [ -d /opt/homebrew/opt/openjdk ] || [ -d /opt/homebrew/opt/openjdk@25 ] || [ -d /usr/lib/jvm ]; then
        case $(df_probe zsh_i JAVA_HOME) in
            unset|"") df_fail "JAVA_HOME is unset while a JDK is installed" ;;
        esac
    fi
    df_render_env zsh_i "$DF_WORK/live.zsh.env"
    df_render_env bash_i "$DF_WORK/live.bash.env"
    df_compare_rendered zsh.env "$DF_WORK/live.zsh.env" "zsh.env"
    df_compare_rendered bash.env "$DF_WORK/live.bash.env" "bash.env"
    df_section_end
}

df_section_alias() {
    df_section_begin "Alias contract"
    df_require_probe zsh_i && df_require_probe zsh_c && df_require_probe bash_i && df_require_probe bash_c || true
    df_expect "$(df_probe zsh_c ls_alias)" "" "zsh -c must not define the ls alias"
    df_expect "$(df_probe bash_c ls_alias)" "" "bash -c must not define the ls alias"
    if [ -z "$(df_probe zsh_i ls_alias)" ]; then
        df_fail "interactive zsh has no ls alias"
    fi
    if [ -z "$(df_probe bash_i ls_alias)" ]; then
        df_fail "interactive bash has no ls alias"
    fi
    df_render_block zsh_i DF_ALIASES_BEGIN DF_ALIASES_END "$DF_WORK/live.zsh.aliases"
    df_render_block bash_i DF_ALIASES_BEGIN DF_ALIASES_END "$DF_WORK/live.bash.aliases"
    df_compare_rendered zsh.aliases "$DF_WORK/live.zsh.aliases" "zsh.aliases"
    df_compare_rendered bash.aliases "$DF_WORK/live.bash.aliases" "bash.aliases"
    df_section_end
}

df_section_functions() {
    local cap name file
    df_section_begin "Function contract"
    for cap in zsh_i bash_i; do
        df_require_probe "$cap" || continue
        file=$DF_WORK/$cap.functions
        df_render_block "$cap" DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$file"
        for name in $DF_REQUIRED_FNS; do
            if ! grep -qx "$name" "$file"; then
                df_fail "$cap is missing function $name"
            fi
        done
        df_expect "$(df_probe "$cap" mkcd_rc)" 0 "$cap mkcd"
        df_expect "$(df_probe "$cap" up_rc)" 0 "$cap up"
        df_expect "$(df_probe "$cap" up_pollute)" 0 "$cap up does not leave its locals"
        df_expect "$(df_probe "$cap" help_rc)" 0 "$cap help"
        df_expect "$(df_probe "$cap" help_stderr)" 0 "$cap help stderr"
        if grep -qx wget "$file"; then
            df_expect "$(df_probe "$cap" wget_rc)" 127 "$cap wget without a URL"
            case $(df_probe "$cap" wget_err) in
                *not\ installed*) ;;
                *) df_fail "$cap wget stderr" "mentions that wget is not installed" "$(df_probe "$cap" wget_err)" ;;
            esac
        fi
    done
    file=$DF_WORK/zsh_c.functions
    df_render_block zsh_c DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$file"
    if grep -qx mkcd "$file"; then
        df_fail "zsh -c defined interactive functions"
    fi
    df_render_block zsh_i DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$DF_WORK/live.zsh.functions"
    df_render_block bash_i DF_FUNCTIONS_BEGIN DF_FUNCTIONS_END "$DF_WORK/live.bash.functions"
    df_compare_rendered zsh.functions "$DF_WORK/live.zsh.functions" "zsh.functions"
    df_compare_rendered bash.functions "$DF_WORK/live.bash.functions" "bash.functions"
    df_render_startup zsh_i "$DF_WORK/live.zsh.startup"
    df_render_startup bash_i "$DF_WORK/live.bash.startup"
    df_compare_rendered zsh.startup "$DF_WORK/live.zsh.startup" "zsh.startup"
    df_compare_rendered bash.startup "$DF_WORK/live.bash.startup" "bash.startup"
    df_section_end
}

df_section_tools() {
    local star fzf
    df_section_begin "Tool initialization"
    df_require_probe zsh_i || { df_section_end; return; }
    df_require_probe zsh_i_tty || { df_section_end; return; }
    df_expect "$(df_probe zsh_i compdef)" 1 "compdef after interactive zsh"
    df_expect "$(df_probe zsh_c compdef)" 0 "compdef is absent in zsh -c"
    df_expect "$(df_probe zsh_i fzf_widget)" 0 "fzf widget stays unloaded without a tty"
    df_expect "$(df_probe zsh_i zsh_highlight)" 0 "syntax highlighting stays unloaded without a tty"
    df_expect "$(df_probe zsh_c starship_precmd)" 0 "starship stays unloaded in zsh -c"
    star=$(df_probe zsh_i cmd_starship)
    if [ -n "$star" ] && [ "$star" != missing ]; then
        df_expect "$(df_probe zsh_i starship_precmd)" 1 "starship_precmd on interactive zsh when starship is installed"
    fi
    fzf=$(df_probe zsh_i cmd_fzf)
    if [ -n "$fzf" ] && [ "$fzf" != missing ]; then
        case $(df_probe zsh_i FZF_DEFAULT_OPTS) in
            *fg:#cdd6f4*) ;;
            *) df_fail "FZF_DEFAULT_OPTS lost the catppuccin marker" "contains fg:#cdd6f4" "$(df_probe zsh_i FZF_DEFAULT_OPTS)" ;;
        esac
    fi
    fzf=$(df_probe zsh_i_tty cmd_fzf)
    if [ -n "$fzf" ] && [ "$fzf" != missing ] && df_fzf_bindings; then
        df_expect "$(df_probe zsh_i_tty fzf_widget)" 1 "fzf-file-widget on an interactive tty"
    fi
    if df_highlight_available; then
        df_expect "$(df_probe zsh_i_tty zsh_highlight)" 1 "syntax highlighting on an interactive tty"
    else
        df_expect "$(df_probe zsh_i_tty zsh_highlight)" 0 "syntax highlighting without a plugin"
    fi
    df_expect "$(df_probe zsh_i gpg_tty)" unset "GPG_TTY unset when stdin and stdout are not ttys"
    df_expect "$(df_probe zsh_i_tty gpg_tty)" set "GPG_TTY set on an interactive tty"
    df_expect "$(df_probe zsh_c gpg_tty)" unset "GPG_TTY unset in zsh -c"
    df_section_end
}

df_section_tty() {
    df_section_begin "TTY behavior"
    df_expect "$(df_probe zsh_i tty_out)" 0 "pipe interactive stdout is not a tty"
    df_expect "$(df_probe zsh_i_tty tty_out)" 1 "pty interactive stdout is a tty"
    df_expect "$(df_probe zsh_i_tty tty_in)" 1 "pty interactive stdin is a tty"
    df_banner_absent zsh_i "interactive zsh pipe"
    df_banner_absent zsh_l "login zsh pipe"
    df_banner_absent bash_i "interactive bash pipe"
    df_banner_match 24 zsh_i_tty "$DF_BASE/banner.24" "top-level interactive zsh terminal"
    df_banner_match 24 zsh_l_tty "$DF_BASE/banner.24" "top-level login zsh terminal"
    df_banner_absent zsh_nested "nested interactive zsh"
    df_section_end
}

df_section_noninteractive() {
    local home got
    df_section_begin "Non-interactive behavior"
    df_expect "$(cat "$DF_WORK/cap/zsh_ls_c.out")" foo "zsh -c preserves LS_COLORS"
    df_expect "$(cat "$DF_WORK/cap/zsh_ls_i.out")" unset "interactive zsh drops inherited LS_COLORS"
    df_pipe_ok zsh_ls_c "LS_COLORS zsh -c"
    df_pipe_ok zsh_ls_i "LS_COLORS zsh -i"
    df_pipe_ok sh_c "sh -c"
    df_pipe_ok sh_l "sh -l"
    df_require_probe sh_c && df_expect "$(df_probe sh_c DOTFILES_DIR)" unset "sh -c does not load ~/.profile"
    if df_require_probe sh_l; then
        df_expect "$(df_probe sh_l DOTFILES_SHELL)" sh "login sh identifies itself"
        got=$(df_probe sh_l DOTFILES_DIR)
        if [ -d "$got" ]; then
            got=$(cd -P "$got" && pwd)
        fi
        home=$(cd -P "$DF_ROOT" && pwd)
        df_expect "$got" "$home" "login sh DOTFILES_DIR"
        df_banner_absent sh_l "login sh"
    fi
    df_banner_absent sh_c "sh -c"
    df_banner_absent zsh_c "non-interactive zsh"
    df_banner_absent bash_c "non-interactive bash"
    df_section_end
}

df_section_banner() {
    df_section_begin "Color banner"
    df_banner_match 24 zsh_i_tty "$DF_BASE/banner.24" "truecolor ribbon"
    df_banner_match 256 zsh_256 "$DF_BASE/banner.256" "256-color ribbon"
    df_banner_match 16 zsh_16 "$DF_BASE/banner.16" "16-color ribbon"
    df_banner_match 24 zsh_iterm "$DF_BASE/banner.24" "TERM_PROGRAM=iTerm.app selects truecolor"
    df_banner_match 24 zsh_l_tty "$DF_BASE/banner.24" "login ribbon"
    df_banner_match 24 bash_i_tty "$DF_BASE/banner.24" "interactive bash ribbon"
    df_banner_match 24 bash_l_tty "$DF_BASE/banner.24" "login bash ribbon"
    df_banner_absent zsh_nested "nested shell ribbon"
    df_banner_absent zsh_i "non-tty interactive ribbon"
    df_banner_absent zsh_c "script ribbon"
    df_banner_absent zsh_c_tty "non-interactive terminal ribbon"
    df_banner_absent bash_c "bash script ribbon"
    if [ -f "$DF_BASE/banner.24" ]; then
        df_note "Banner: truecolor $(head -n 1 "$DF_BASE/banner.24")"
    fi
    df_section_end
}

df_section_ansi() {
    local cap
    df_section_begin "ANSI output"
    for cap in zsh_c zsh_i zsh_l bash_c bash_env bash_i bash_l sh_c sh_l zsh_ls_c zsh_ls_i; do
        df_no_esc "$DF_WORK/cap/$cap.out" "$cap stdout"
        df_no_esc "$DF_WORK/cap/$cap.err" "$cap stderr"
    done
    df_banner_match 24 zsh_i_tty "$DF_BASE/banner.24" "ribbon reset and hue order"
    df_section_end
}

df_section_launchctl() {
    local n1 n2 n3
    df_section_begin "Launchctl publish"
    sb_create
    sb_env_defaults
    SB_SHELL_BIN=$DF_ZSH
    df_capture lc_i pipe "$DF_ZSH" -i -c exit
    cp "$SB_LOG" "$DF_WORK/lc.after-interactive"
    df_capture lc_l1 pipe "$DF_ZSH" -l -i -c exit
    cp "$SB_LOG" "$DF_WORK/lc.after-login1"
    df_capture lc_l2 pipe "$DF_ZSH" -l -i -c exit
    cp "$SB_LOG" "$DF_WORK/lc.after-login2"
    df_pipe_ok lc_i "non-login before launchctl"
    df_pipe_ok lc_l1 "first login launchctl"
    df_pipe_ok lc_l2 "second login launchctl"
    n1=$(grep -c '^setenv ' "$DF_WORK/lc.after-interactive" || true)
    n2=$(grep -c '^setenv ' "$DF_WORK/lc.after-login1" || true)
    n3=$(grep -c '^setenv ' "$DF_WORK/lc.after-login2" || true)
    df_expect "$n1" 0 "non-login zsh does not call launchctl" "0" "$n1"
    df_expect "$n2" 3 "first login publishes PATH, EDITOR, and LANG" "3" "$n2"
    df_expect "$n3" 3 "second login does not publish again" "3" "$n3"
    grep -q '^setenv PATH ' "$DF_WORK/lc.after-login1" || df_fail "first login did not setenv PATH"
    grep -q '^setenv EDITOR ' "$DF_WORK/lc.after-login1" || df_fail "first login did not setenv EDITOR"
    grep -q '^setenv LANG ' "$DF_WORK/lc.after-login1" || df_fail "first login did not setenv LANG"
    sb_destroy
    df_section_end
}

df_section_missing() {
    local home got
    df_section_begin "Missing optional tools"
    home=$(cat "$DF_WORK/cap/zsh_i.home")
    if [ ! -d "$home/.nvm" ]; then
        df_expect "$(df_probe zsh_i NVM_DIR)" "$home/.nvm" "NVM_DIR is set even when ~/.nvm is absent"
    fi
    df_pipe_ok zsh_i "startup while nvm, pyenv, fnm, kubectl, and wget may be absent"
    sb_create
    ln -sf "$DF_ROOT/tests/fixtures/bin/fail-tool" "$SB_HOME/.local/bin/starship"
    ln -sf "$DF_ROOT/tests/fixtures/bin/fail-tool" "$SB_HOME/.local/bin/zoxide"
    if [ ! -d "$SB_HOME/.local/share/mise/shims" ]; then
        mkdir -p "$SB_HOME/.local/share/mise/shims"
    fi
    sb_env_defaults
    SB_SHELL_BIN=$DF_ZSH
    df_capture miss_i pipe "$DF_ZSH" -i -c ". '$DF_LIB/probe.sh'"
    df_pipe_ok miss_i "startup when starship and zoxide fail"
    if df_require_probe miss_i; then
        df_expect "$(df_probe miss_i starship_precmd)" 0 "a failing starship does not leave starship_precmd"
        df_expect "$(df_probe miss_i mkcd_rc)" 0 "mkcd while optional CLIs fail"
        df_expect "$(df_probe miss_i help_rc)" 0 "help while optional CLIs fail"
        df_banner_absent miss_i "failing optional CLIs"
        got=$(cat "$DF_WORK/cap/miss_i.home")
        df_assert_path "$(df_probe miss_i path)" "failing optional CLIs" "$got" miss_i
    fi
    sb_destroy
    df_section_end
}

df_time_variant() {
    local key=$1 mode=$2
    shift 2
    local i=0
    sb_write_env
    df_run "$mode" "$@"
    if [ "$DF_RC" != 0 ]; then
        df_fail "$key warmup exited $DF_RC
$(head -n 20 "$DF_ERR")"
        return 1
    fi
    : > "$DF_WORK/$key.times"
    while [ "$i" -lt "$DF_ITERS" ]; do
        df_run "$mode" "$@"
        if [ "$DF_RC" != 0 ]; then
            df_fail "$key iteration $((i + 1)) exited $DF_RC
$(head -n 20 "$DF_ERR")"
            return 1
        fi
        printf '%s\n' "$DF_MS" >> "$DF_WORK/$key.times"
        i=$((i + 1))
    done
    if ! df_stats < "$DF_WORK/$key.times" > "$DF_WORK/$key.stats"; then
        df_fail "$key could not compute min/median/max"
        return 1
    fi
    return 0
}

df_perf_report_one() {
    local key=$1 pretty=$2 stats min med max base result limit verdict
    if [ ! -s "$DF_WORK/$key.stats" ]; then
        return 0
    fi
    stats=$(cat "$DF_WORK/$key.stats")
    # shellcheck disable=SC2086
    set -- $stats
    min=$1
    med=$2
    max=$3
    base=$(awk -F= -v k="${key}_median" '$1==k {print substr($0, length(k)+2); exit}' "$DF_BASE/timing.env" 2>/dev/null || true)
    if [ -z "$base" ]; then
        df_fail "No timing baseline for $pretty. Run ./tests/run.sh --update-baseline"
        df_note "$pretty: min ${min} median ${med} max ${max} ms (no baseline)"
        return 1
    fi
    result=$(df_over_limit "$med" "$base" "$DF_RATIO" "$DF_SLACK") || {
        df_fail "$pretty threshold calculation failed"
        return 1
    }
    limit=${result%% *}
    verdict=${result##* }
    df_note "$pretty: min ${min} median ${med} max ${max} ms; baseline ${base}; limit ${limit}"
    if [ "$verdict" != ok ]; then
        df_fail "$pretty median regressed
iterations: $DF_ITERS
minimum:    ${min} ms
median:     ${med} ms
maximum:    ${max} ms
baseline:   ${base} ms
limit:      ${limit} ms (max of ${DF_RATIO}x and +${DF_SLACK} ms)"
        return 1
    fi
    return 0
}

df_write_timing() {
    local key stats min med max
    {
        printf '%s\n' '# Steady-state milliseconds after one uncounted warmup in the same sandbox.'
        printf '%s\n' '# Login figures include logout. brew outdated is not part of the sample.'
        printf 'iterations=%s\n' "$DF_ITERS"
        for key in zsh_i_pipe zsh_i_tty zsh_l_tty zsh_c_pipe bash_i_pipe bash_l_pipe; do
            [ -s "$DF_WORK/$key.stats" ] || continue
            stats=$(cat "$DF_WORK/$key.stats")
            # shellcheck disable=SC2086
            set -- $stats
            min=$1
            med=$2
            max=$3
            printf '%s_min=%s\n' "$key" "$min"
            printf '%s_median=%s\n' "$key" "$med"
            printf '%s_max=%s\n' "$key" "$max"
        done
    } > "$DF_BASE/timing.env"
}

df_section_perf() {
    df_section_begin "Startup performance"
    sb_create
    sb_env_defaults
    SB_SHELL_BIN=$DF_ZSH
    df_time_variant zsh_i_pipe pipe "$DF_ZSH" -i -c exit || true
    SB_COLORTERM_SET=1
    SB_COLORTERM=truecolor
    df_time_variant zsh_i_tty pty "$DF_ZSH" -i -c exit || true
    df_time_variant zsh_l_tty pty "$DF_ZSH" -l -i -c exit || true
    SB_COLORTERM_SET=0
    SB_COLORTERM=
    df_time_variant zsh_c_pipe pipe "$DF_ZSH" -c exit || true
    SB_SHELL_BIN=$DF_BASH
    df_time_variant bash_i_pipe pipe "$DF_BASH" -i -c exit || true
    df_time_variant bash_l_pipe pipe "$DF_BASH" --login -i -c exit || true
    if [ "$DF_UPDATE" = 1 ]; then
        mkdir -p "$DF_BASE"
        df_write_timing
    fi
    if [ ! -f "$DF_BASE/timing.env" ]; then
        df_fail "No timing baseline. Run ./tests/run.sh --update-baseline"
    else
        df_perf_report_one zsh_i_pipe "zsh -i pipe" || true
        df_perf_report_one zsh_i_tty "zsh -i tty" || true
        df_perf_report_one zsh_l_tty "zsh -l -i tty" || true
        df_perf_report_one zsh_c_pipe "zsh -c pipe" || true
        df_perf_report_one bash_i_pipe "bash -i pipe" || true
        df_perf_report_one bash_l_pipe "bash --login -i pipe" || true
    fi
    sb_destroy
    df_section_end
}

df_section_isolation() {
    local extra missing
    df_section_begin "Sandbox isolation"
    df_safety_digests "$DF_WORK/safety.after.digests"
    if ! diff -q "$DF_WORK/safety.before.digests" "$DF_WORK/safety.after.digests" >/dev/null; then
        df_fail "A real file outside the sandbox changed:
$(diff -u "$DF_WORK/safety.before.digests" "$DF_WORK/safety.after.digests")"
    fi
    git -C "$DF_ROOT" status --porcelain | LC_ALL=C sort > "$DF_WORK/safety.after.status"
    if [ "$DF_UPDATE" = 1 ]; then
        extra=$(comm -13 "$DF_WORK/safety.before.status" "$DF_WORK/safety.after.status" | grep -v 'tests/baseline' || true)
    else
        extra=$(comm -13 "$DF_WORK/safety.before.status" "$DF_WORK/safety.after.status" || true)
        missing=$(comm -23 "$DF_WORK/safety.before.status" "$DF_WORK/safety.after.status" || true)
        if [ -n "${missing:-}" ]; then
            df_fail "Git status lost entries:
$missing"
        fi
    fi
    if [ -n "$extra" ]; then
        df_fail "Git status gained entries outside tests/baseline:
$extra"
    fi
    df_section_end
}

df_safety_digests() {
    local f
    {
        df_digest "$HOME/.local/state/shell/launchctl.stamp"
        for f in "$HOME/.cache/zsh"/.zcompdump-*; do
            [ -e "$f" ] || continue
            df_digest "$f"
        done
        df_digest "$HOME/.gitconfig"
    } > "$1"
}

df_safety_status() {
    git -C "$DF_ROOT" status --porcelain | LC_ALL=C sort > "$DF_WORK/safety.before.status"
    df_safety_digests "$DF_WORK/safety.before.digests"
}
