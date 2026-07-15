# prompt.bash — Bash prompt with Git status
# Skipped when starship is installed (initialized later in tools.bash).

if command -v starship >/dev/null 2>&1; then
    return 0 2>/dev/null || true
fi

_color_prompt=
case "${TERM:-}" in
    *color*|*-256color|xterm*|screen*|tmux*) _color_prompt=yes ;;
esac
if [ -z "$_color_prompt" ] && [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
    _color_prompt=yes
fi

__git_prompt() {
    git rev-parse --git-dir >/dev/null 2>&1 || return 0
    _branch=$(git symbolic-ref --short HEAD 2>/dev/null \
        || git describe --tags --exact-match 2>/dev/null \
        || git rev-parse --short HEAD 2>/dev/null) || true
    [ -z "${_branch:-}" ] && return 0

    _dirty= _staged= _untracked=
    git diff --quiet 2>/dev/null || _dirty='●'
    git diff --quiet --cached 2>/dev/null || _staged='+'
    [ -n "$(git ls-files --other --exclude-standard 2>/dev/null)" ] && _untracked='?'
    _status="${_dirty}${_staged}${_untracked}"

    if [ "$_color_prompt" = yes ]; then
        if [ -n "$_status" ]; then
            printf ' \033[0;36m[\033[1;31m%s\033[0;33m%s\033[0;36m]\033[0m' "$_branch" "$_status"
        else
            printf ' \033[0;36m[\033[1;32m%s\033[0;36m]\033[0m' "$_branch"
        fi
    else
        printf ' [%s%s]' "$_branch" "$_status"
    fi
    unset _branch _dirty _staged _untracked _status
}

__prompt_arrow() {
    if [ $? -eq 0 ]; then
        printf '\033[1;32m❯\033[0m'
    else
        printf '\033[1;31m❯\033[0m'
    fi
}

if [ "$_color_prompt" = yes ]; then
    PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;34m\][\w]\[\033[0m\]$(__git_prompt) \[\033[1;34m\][\D{%H:%M:%S}]\[\033[0m\]\n$(__prompt_arrow) '
else
    PS1='\u@\h [\w]$(__git_prompt) [\D{%H:%M:%S}]\n❯ '
fi

case "${TERM:-}" in
    xterm*|rxvt*|screen*|tmux*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
esac

unset _color_prompt
