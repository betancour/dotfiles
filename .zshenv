# LSCOLORS environment variable
# Defines colors for different file types in the ls command

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export CLICOLOR=1

if [[ "$OSTYPE" == "linux-gnu"* ]]; then  # For Linux
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
elif [[ "$OSTYPE" == "darwin"* ]]; then   # For macOS
    export LSCOLORS="GxFxCxDxBxegedabagaced"
else
    echo "Unsupported OS"
fi

# Removed commented-out cargo env line
# Original: . "$HOME/.cargo/env"
