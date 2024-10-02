# LSCOLORS environment variable
#
## This file defines the colors to use for different file types and attributes
# in the ls command.
#

if [[ "$OSTYPE" == "linux-gnu"* ]]; then ## For Linux
    ## Light theme
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
    ## Dark theme
    export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
elif [[ "$OSTYPE" == "darwin"* ]]; then  ## For macOS
    ## Light theme
    export LSCOLORS="exfxcxdxbxegedabagacad"
    ## Dark theme
    export LSCOLORS="Gxfxcxdzxbxegedabagacad"
else
    echo "Unsupported OS"
fi
