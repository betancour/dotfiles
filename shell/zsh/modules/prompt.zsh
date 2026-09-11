# prompt.zsh — Zsh prompt with vcs_info Git integration
# Skipped when starship is installed (initialized later in tools.zsh).

if [[ "${TERM:-}" != dumb ]] && command -v starship >/dev/null 2>&1; then
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

# Branch + dirty markers come from vcs_info (one git walk; no extra porcelain).
_dotfiles_vcs_prompt() {
    vcs_info
    [[ -z "${vcs_info_msg_0_:-}" ]] && return
    print -n "%F{green}[${vcs_info_msg_0_}]%f"
}

PROMPT='
%F{green}%n%f@%F{green}%m%f %F{green}[%3~]%f$(_dotfiles_vcs_prompt) %F{green}[%D{%H:%M:%S}]%f
%(?.%F{green}❯%f.%K{green}%F{black}❯%f%k) '

RPROMPT='%(?..%K{green}%F{black}[%?]%f%k)'
