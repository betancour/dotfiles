# .zprofile
# User specific environment and startup programs
# Load .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi

if [ -f "$HOME/.zaliases" ]; then
  source "$HOME/.zaliases"
fi

if [ -f $HOME/.zshenv ]; then
        source $HOME/.zshenv
fi

if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi

