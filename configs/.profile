if [ -n "$ZSH_VERSION" ]; then
	if [ -f "$HOME/.vimrc" ]; then
		. "$HOME/.vimrc"
	fi
fi
if [ -d "$HOME/bin" ]; then
	PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi
