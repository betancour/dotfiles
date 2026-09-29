# completion.zsh — Zsh completion system

export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST}-${ZSH_VERSION}"
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Extra completion directories. Prepend, then keep the first copy of each
# path: Homebrew's zsh already ships site-functions, sometimes twice.
_df_fpath_prepend() {
    [[ -d $1 ]] || return 0
    fpath=("$1" $fpath)
}
_df_fpath_prepend /opt/homebrew/share/zsh-completions
_df_fpath_prepend /usr/local/share/zsh-completions
_df_fpath_prepend /opt/homebrew/share/zsh/site-functions
_df_fpath_prepend /usr/local/share/zsh/site-functions
_df_fpath_prepend /Applications/Docker.app/Contents/Resources/etc
_df_fpath_prepend "$HOME/.grok/completions/zsh"
typeset -U fpath
unset -f _df_fpath_prepend

# Skip fpath security audit (compaudit) — the dump is under our cache dir.
ZSH_DISABLE_COMPFIX=true

autoload -Uz compinit
# Oh My Zsh's oh-my-zsh.sh calls compinit itself; skip the duplicate dump.
if [[ "${DOTFILES_USE_OMZ:-0}" != 1 ]]; then
    # Reuse dump when younger than 24h (-C skips security check → faster startup)
    if [[ -f "$ZSH_COMPDUMP"(#qN.mh-24) ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -d "$ZSH_COMPDUMP"
    fi
    autoload -Uz bashcompinit && bashcompinit
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"

if (( $+functions[compdef] )); then
    compdef _files backup fsize extract
    compdef _directories mkcd cdf finddir
fi
