# dotfiles
** Dotfiles for a fresh Linux Install based on BASH

Possibly will be migrated for using ZSH.
So, use is not guaranteed.


to run script 

sh -c "$(curl -#fL raw.github.com/betancour/dotfiles/main/install.sh)"


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
