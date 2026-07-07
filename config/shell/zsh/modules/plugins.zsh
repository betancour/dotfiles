# plugins.zsh — Oh My Zsh and plugin loading

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    CASE_SENSITIVE="false"
    HYPHEN_INSENSITIVE="true"
    DISABLE_AUTO_UPDATE="true"
    DISABLE_UPDATE_PROMPT="true"
    ENABLE_CORRECTION="true"
    COMPLETION_WAITING_DOTS="true"
    DISABLE_UNTRACKED_FILES_DIRTY="true"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker kubectl brew macos)
    source "$ZSH/oh-my-zsh.sh"
else
    for plugin_path in \
        /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
        [[ -f "$plugin_path" ]] && source "$plugin_path" && break
    done

    for plugin_path in \
        /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
        [[ -f "$plugin_path" ]] && source "$plugin_path" && break
    done
fi