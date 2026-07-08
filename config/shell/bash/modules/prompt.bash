# --- Terminal Color Setup ---
color_prompt=
case "$TERM" in
    xterm-color|*-256color|*-color) color_prompt=yes ;;
esac

if [[ -z "$color_prompt" && -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null 2>&1; then
    color_prompt=yes
fi

# --- Git Prompt ---
__git_prompt() {
    local git_branch git_status git_dirty git_staged git_untracked
    git rev-parse --git-dir >/dev/null 2>&1 || return
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -z "$git_branch" ]] && return

    git_dirty='' git_staged='' git_untracked=''
    git diff --quiet 2>/dev/null || git_dirty='●'
    git diff --quiet --cached 2>/dev/null || git_staged='+'
    [[ -n $(git ls-files --other --exclude-standard 2>/dev/null) ]] && git_untracked='?'

    git_status="${git_dirty}${git_staged}${git_untracked}"

    if [[ "$color_prompt" == yes ]]; then
        if [[ -n "$git_status" ]]; then
            echo -e " \033[0;36m[\033[1;31m${git_branch}\033[0;33m${git_status}\033[0;36m]\033[0m"
        else
            echo -e " \033[0;36m[\033[1;32m${git_branch}\033[0;36m]\033[0m"
        fi
    else
        echo " [${git_branch}${git_status}]"
    fi
}

# --- Prompt Arrow con color dinámico ---
__prompt_arrow() {
    if [[ $? -eq 0 ]]; then
        printf "\033[1;32m❯\033[0m"   # Verde
    else
        printf "\033[1;31m❯\033[0m"   # Rojo
    fi
}

# --- Prompt Final ---
if [[ "$color_prompt" == yes ]]; then
    PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;34m\][\w]\[\033[0m\]$(__git_prompt) \[\033[1;34m\][\D{%H:%M:%S}]\[\033[0m\]\n$(__prompt_arrow) '
else
    PS1='\u@\h [\w]$(__git_prompt) [\D{%H:%M:%S}]\n❯ '
fi

# Terminal Title
case "$TERM" in
    xterm*|rxvt*|screen*|tmux*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
esac
