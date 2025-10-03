# Defines colors for different file types in the ls command

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export CLICOLOR=1

# LSCOLORS environment variable

if [[ "$OSTYPE" == "linux-gnu"* ]]; then  # For Linux
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
elif [[ "$OSTYPE" == "darwin"* ]]; then   # For macOS
    export LSCOLORS="GxFxCxDxBxegedabagaced"
else
    echo "Unsupported OS"
fi

# Set up the PATH
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export ZSH_COMPDUMP="$HOME/.cache/zcompdump"
export TERM="$TERM"
export LANG="en_US.UTF-8"
export GIT_HOME="$HOME/.git"
