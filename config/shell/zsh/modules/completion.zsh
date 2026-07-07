# completion.zsh — Zsh completion system

export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${(%):-%m}-${ZSH_VERSION}"
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Grok completions (add to fpath before compinit, no second compinit)
[[ -d "$HOME/.grok/completions/zsh" ]] && fpath=("$HOME/.grok/completions/zsh" $fpath)

autoload -U compinit
local -a compinit_flags=(-d "$ZSH_COMPDUMP")
if [[ -f "$ZSH_COMPDUMP" ]]; then
    local -a zstat_mtime
    zstat -A zstat_mtime +mtime "$ZSH_COMPDUMP" 2>/dev/null
    if [[ -n "${zstat_mtime[1]:-}" ]]; then
        local age_days=$(( (EPOCHSECONDS - zstat_mtime[1]) / 86400 ))
        (( age_days < 1 )) && compinit_flags=(-C "${compinit_flags[@]}")
    fi
fi
compinit "${compinit_flags[@]}"

autoload -U bashcompinit && bashcompinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"

# Custom function completions
if command -v compdef >/dev/null 2>&1; then
    compdef _files backup fsize extract count replace
    compdef _directories mkcd cdf finddir
fi