# LSCOLORS environment variable
#
## This file defines the colors to use for different file types and attributes
# in the ls command.
#

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ "$OSTYPE" == "linux-gnu"* ]]; then  # For Linux
    export LS_COLORS='di=1;0;40:ln=0;1;44:so=35;1;46:pi=30;41:ex=1;31;40:bd=1;36;40:cd=30;1;46:su=0;1;42:sg=0;1;41' # Dark theme
elif [[ "$OSTYPE" == "darwin"* ]]; then  # For macOS
    export CLICOLOR=1
    export LSCOLORS="EafGaEadBaGafHaDa" # Dark theme
else
    echo "Unsupported OS"
fi

#. "$HOME/.cargo/env"
