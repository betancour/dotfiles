# Dotfiles 🖥️✨

Welcome to my dotfiles repository! This collection of configurations is designed to enhance your command-line experience on both **Linux** and **macOS**. Let’s make your terminal as awesome as you are!

## ZSH: Z Shell Configuration 🌊

Zsh is not just a shell; it's a whole new world! To supercharge your Zsh setup, we’re going to enable some snazzy plugins: **zsh-autosuggestions** and **zsh-syntax-highlighting**.

### Enabling Plugins 🚀

# ZSH

## Enabling Plugins (zsh-autosuggestions & zsh-syntax-highlighting)
 - Download zsh-autosuggestions by

 `git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions`

 - Download zsh-syntax-highlighting by

 `git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting`

 - `nano ~/.zshrc` find `plugins=(git)`

 - Append `zsh-autosuggestions & zsh-syntax-highlighting` to  `plugins()` like this

 `plugins=(git zsh-autosuggestions zsh-syntax-highlighting)`

 - Reopen terminal
