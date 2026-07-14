# plugins.zsh — optional Oh My Zsh and standalone plugins
# Prefer system/Homebrew plugins when OMZ is absent (faster, fewer deps).

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME=""
    CASE_SENSITIVE=false
    HYPHEN_INSENSITIVE=true
    DISABLE_AUTO_UPDATE=true
    DISABLE_UPDATE_PROMPT=true
    ENABLE_CORRECTION=false
    COMPLETION_WAITING_DOTS=true
    DISABLE_UNTRACKED_FILES_DIRTY=true
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    # shellcheck source=/dev/null
    source "$ZSH/oh-my-zsh.sh"
else
    for _p in \
        /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
    do
        [[ -f "$_p" ]] && source "$_p" && break
    done

    for _p in \
        /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    do
        [[ -f "$_p" ]] && source "$_p" && break
    done
    unset _p
fi
