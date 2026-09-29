#!/bin/sh
# Contract probe. Runs inside the shell under test and prints a marked block.
# Parsed by sh, Bash, and Zsh: no shell-specific syntax outside eval strings.
# Always exits 0. Callers read the fields; they do not use this status as
# a substitute for the shell's own startup status when the probe did not run.

_dfp_has_fn() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "whence -w \"$1\"" 2>/dev/null | grep -q ': function$'
        return $?
    fi
    [ "$(type -t "$1" 2>/dev/null)" = "function" ]
}

_dfp_kv() {
    eval "_dfp_set=\${$1+x}"
    if [ -z "${_dfp_set}" ]; then
        printf '%s=unset\n' "$1"
    else
        eval "_dfp_val=\${$1}"
        printf '%s=%s\n' "$1" "$_dfp_val"
    fi
}

printf '%s\n' 'DF_PROBE_BEGIN'

_dfp_shell=sh
_dfp_ver=
if [ -n "${ZSH_VERSION:-}" ]; then
    _dfp_shell=zsh
    _dfp_ver=$ZSH_VERSION
elif [ -n "${BASH_VERSION:-}" ]; then
    _dfp_shell=bash
    _dfp_ver=$BASH_VERSION
fi
printf 'shell=%s\n' "$_dfp_shell"
printf 'version=%s\n' "$_dfp_ver"

_dfp_interactive=0
case $- in
    *i*) _dfp_interactive=1 ;;
esac
printf 'interactive=%s\n' "$_dfp_interactive"

_dfp_login=0
if [ -n "${ZSH_VERSION:-}" ]; then
    eval '[[ -o login ]] && _dfp_login=1'
elif [ -n "${BASH_VERSION:-}" ]; then
    if shopt -q login_shell 2>/dev/null; then
        _dfp_login=1
    fi
fi
printf 'login=%s\n' "$_dfp_login"

if [ -t 1 ]; then printf 'tty_out=1\n'; else printf 'tty_out=0\n'; fi
if [ -t 0 ]; then printf 'tty_in=1\n'; else printf 'tty_in=0\n'; fi
printf 'umask=%s\n' "$(umask)"
printf 'path=%s\n' "${PATH-}"

_dfp_kv EDITOR
_dfp_kv VISUAL
_dfp_kv LANG
_dfp_kv LC_CTYPE
_dfp_kv LC_ALL
_dfp_kv PAGER
_dfp_kv HISTSIZE
_dfp_kv SAVEHIST
_dfp_kv HISTFILE
_dfp_kv HOMEBREW_PREFIX
_dfp_kv HOMEBREW_CELLAR
_dfp_kv DOTFILES_DIR
_dfp_kv DOTFILES_SHELL
_dfp_kv XDG_CONFIG_HOME
_dfp_kv XDG_DATA_HOME
_dfp_kv XDG_STATE_HOME
_dfp_kv XDG_CACHE_HOME
_dfp_kv JAVA_HOME
_dfp_kv BUN_INSTALL
_dfp_kv NVM_DIR
_dfp_kv BAT_CONFIG_PATH
_dfp_kv RIPGREP_CONFIG_PATH
_dfp_kv FZF_DEFAULT_OPTS

if [ -n "${GPG_TTY+x}" ]; then
    printf 'gpg_tty=set\n'
else
    printf 'gpg_tty=unset\n'
fi

_dfp_opt() {
    printf '%s=na\n' "$1"
}
if [ -n "${ZSH_VERSION:-}" ]; then
    eval '[[ -o globdots ]] && printf "globdots=1\n" || printf "globdots=0\n"'
    eval '[[ -o extendedglob ]] && printf "extendedglob=1\n" || printf "extendedglob=0\n"'
    eval '[[ -o nullglob ]] && printf "nullglob=1\n" || printf "nullglob=0\n"'
    eval '[[ -o beep ]] && printf "beep=1\n" || printf "beep=0\n"'
    eval '[[ -o sharehistory ]] && printf "sharehistory=1\n" || printf "sharehistory=0\n"'
    eval 'whence -w compdef >/dev/null 2>&1 && printf "compdef=1\n" || printf "compdef=0\n"'
    eval '{ whence -w prompt_starship_precmd >/dev/null 2>&1 || whence -w starship_precmd >/dev/null 2>&1; } && printf "starship_precmd=1\n" || printf "starship_precmd=0\n"'
    eval 'whence -w fzf-file-widget >/dev/null 2>&1 && printf "fzf_widget=1\n" || printf "fzf_widget=0\n"'
    eval 'whence -w _zsh_highlight >/dev/null 2>&1 && printf "zsh_highlight=1\n" || printf "zsh_highlight=0\n"'
elif [ -n "${BASH_VERSION:-}" ]; then
    if shopt -q nullglob 2>/dev/null; then printf 'nullglob=1\n'; else printf 'nullglob=0\n'; fi
    if shopt -q dotglob 2>/dev/null; then printf 'globdots=1\n'; else printf 'globdots=0\n'; fi
    printf 'extendedglob=na\n'
    printf 'beep=na\n'
    printf 'sharehistory=na\n'
    printf 'compdef=na\n'
    printf 'starship_precmd=na\n'
    printf 'fzf_widget=na\n'
    printf 'zsh_highlight=na\n'
else
    _dfp_opt globdots
    _dfp_opt nullglob
    _dfp_opt extendedglob
    _dfp_opt beep
    _dfp_opt sharehistory
    _dfp_opt compdef
    _dfp_opt starship_precmd
    _dfp_opt fzf_widget
    _dfp_opt zsh_highlight
fi

if [ -n "${PROMPT:-}${PS1:-}" ]; then
    printf 'prompt_set=1\n'
else
    printf 'prompt_set=0\n'
fi

_dfp_ls=$(alias ls 2>/dev/null) || _dfp_ls=
printf 'ls_alias=%s\n' "$_dfp_ls"

_dfp_cmd() {
    _dfp_p=$(command -v "$1" 2>/dev/null) || _dfp_p=missing
    printf 'cmd_%s=%s\n' "$1" "$_dfp_p"
}
_dfp_cmd java
_dfp_cmd node
_dfp_cmd brew
_dfp_cmd git
_dfp_cmd nvim
_dfp_cmd launchctl
_dfp_cmd starship
_dfp_cmd zoxide
_dfp_cmd fzf
_dfp_cmd kubectl
_dfp_cmd wget

printf 'mkcd_rc=skip\n'
printf 'up_rc=skip\n'
printf 'help_rc=skip\n'
printf 'help_stderr=skip\n'
printf 'up_pollute=skip\n'
printf 'wget_rc=skip\n'
printf 'wget_err=\n'

if [ "$_dfp_interactive" = 1 ]; then
    _dfp_base=${TMPDIR:-/tmp}/dfprobe$$
    mkdir -p "$_dfp_base/a" 2>/dev/null || true
    # TMPDIR on macOS lives under /var, which is a symlink. Compare physical paths.
    # Interactive zsh aliases cd to z when a zoxide binary is visible, even if
    # init failed and z was never defined. `command cd` is not a substitute:
    # zsh's command skips builtins. builtin cd is the real directory change.
    # This block runs only for interactive bash and zsh.
    _dfp_parent=$(builtin cd "$_dfp_base/a" 2>/dev/null && pwd -P) || _dfp_parent=
    _dfp_mk=1
    if mkcd "$_dfp_base/a/b" 2>/dev/null; then
        if [ "$(pwd -P)" = "$_dfp_parent/b" ]; then
            _dfp_mk=0
        fi
    fi
    printf 'mkcd_rc=%s\n' "$_dfp_mk"
    _dfp_up=1
    if up 1 2>/dev/null; then
        if [ "$(pwd -P)" = "$_dfp_parent" ]; then
            _dfp_up=0
        fi
    fi
    printf 'up_rc=%s\n' "$_dfp_up"
    if [ -n "${_levels+x}${_path+x}${_i+x}" ]; then
        printf 'up_pollute=1\n'
    else
        printf 'up_pollute=0\n'
    fi
    _dfp_help=1
    if help >/dev/null 2>"$_dfp_base/help.err"; then
        _dfp_help=0
    fi
    printf 'help_rc=%s\n' "$_dfp_help"
    if [ -s "$_dfp_base/help.err" ]; then
        printf 'help_stderr=1\n'
    else
        printf 'help_stderr=0\n'
    fi
    if _dfp_has_fn wget; then
        _dfp_w=0
        wget >/dev/null 2>"$_dfp_base/wget.err" || _dfp_w=$?
        printf 'wget_rc=%s\n' "$_dfp_w"
        _dfp_we=$(head -n 1 "$_dfp_base/wget.err" 2>/dev/null || true)
        printf 'wget_err=%s\n' "$_dfp_we"
    fi
fi

printf '%s\n' 'DF_PROBE_END'
printf '%s\n' 'DF_ALIASES_BEGIN'
if [ "$_dfp_interactive" = 1 ]; then
    alias 2>/dev/null | LC_ALL=C sort
fi
printf '%s\n' 'DF_ALIASES_END'
printf '%s\n' 'DF_FUNCTIONS_BEGIN'
for _dfp_name in \
    n mkcd up cdf extract findfile finddir fsize backup sysinfo myip localip \
    gitcp gitbr gitlog dpshow dclean genpass weather \
    install-java-tools update-java-tools java-tools-status help reload wget
do
    if _dfp_has_fn "$_dfp_name"; then
        printf '%s\n' "$_dfp_name"
    fi
done
printf '%s\n' 'DF_FUNCTIONS_END'
exit 0
