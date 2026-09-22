# prompt.bash — Bash prompt with Git status
# Skipped when starship is installed (initialized later in tools.bash).

if [ "${TERM:-}" != dumb ] && command -v starship >/dev/null 2>&1; then
    return 0 2>/dev/null || true
fi

__git_prompt() {
    git rev-parse --git-dir >/dev/null 2>&1 || return 0
    _branch=$(git symbolic-ref --short HEAD 2>/dev/null \
        || git describe --tags --exact-match 2>/dev/null \
        || git rev-parse --short HEAD 2>/dev/null) || true
    [ -z "${_branch:-}" ] && return 0

    _dirty= _staged= _untracked= _line=
    while IFS= read -r _line || [ -n "$_line" ]; do
        case $_line in
            \?\?*) _untracked='?' ;;
            \ ?*)  _dirty='●' ;;
            ?\ *)  _staged='+' ;;
            ??*)   _staged='+'; _dirty='●' ;;
        esac
    done <<EOF
$(git status --porcelain 2>/dev/null)
EOF
    _status="${_dirty}${_staged}${_untracked}"
    unset _line

    if [ -n "$_status" ]; then
        printf ' [%s%s]' "$_branch" "$_status"
    else
        printf ' [%s]' "$_branch"
    fi
    unset _branch _dirty _staged _untracked _status
}

__prompt_arrow() {
    if [ $? -eq 0 ]; then
        printf '❯'
    else
        printf '❯'
    fi
}

PS1='\u@\h [\w]$(__git_prompt) [\D{%H:%M:%S}]\n$(__prompt_arrow) '

case "${TERM:-}" in
    xterm*|rxvt*|screen*|tmux*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
esac
