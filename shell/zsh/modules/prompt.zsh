# prompt.zsh — Zsh prompt with vcs_info Git integration
# Skipped when starship is installed (initialized later in tools.zsh).

if command -v starship >/dev/null 2>&1; then
    return 0
fi

autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%b%u%c'
zstyle ':vcs_info:git:*' actionformats '%b|%a%u%c'

# Lightweight git dirty indicator (one porcelain call max)
_dotfiles_vcs_prompt() {
    vcs_info
    [[ -z "${vcs_info_msg_0_:-}" ]] && return

    local git_status status_output
    status_output=$(git status --porcelain 2>/dev/null)
    if [[ -n "$status_output" ]]; then
        git_status="%F{red}●%f"
    else
        git_status="%F{green}✓%f"
    fi
    print -n "%F{blue}[%F{cyan}${vcs_info_msg_0_}%f ${git_status}%F{blue}]%f"
}

PROMPT='
%F{magenta}%n%f@%F{cyan}%m%f %F{blue}[%3~]%f$(_dotfiles_vcs_prompt) %F{blue}[%D{%H:%M:%S}]%f
%(?.%F{green}.%F{red})❯%f '

RPROMPT='%(?..%F{red}[%?]%f)'
