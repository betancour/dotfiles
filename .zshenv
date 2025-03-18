# LSCOLORS environment variable
#
## This file defines the colors to use for different file types and attributes
# in the ls command.
#

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ "$OSTYPE" == "linux-gnu"* ]]; then  # For Linux
    export LS_COLORS="di=1;32:ln=0;1;44:so=30;1;46:pi=0;43:ex=1;31;40:bd=1;36;40:cd=0;1;45:su=0;1;41:sg=0;1;42:tw=1;31;1;44:ow=1;0"
elif [[ "$OSTYPE" == "darwin"* ]]; then  # For macOS
    export LSCOLORS="CxxEaGxdBaGaxFxBxCBEX"
else
    echo "Unsupported OS"
fi

#. "$HOME/.cargo/env"
