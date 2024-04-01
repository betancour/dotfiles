#!/bin/sh
#
# https://gist.github.com/SamSpiri/4466d0aeff694fb6e9019dd6d3b63770
#

# Install zsh. 
sudo apt install -y zsh; 

# powerlevel10k
sh -c "$(curl -s -L https://github.com/OpusCapita/zsh-in-docker/raw/master/zsh-in-docker.sh)" -- \
    -a 'CASE_SENSITIVE="true"' \
    -p git \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting

# get & overwrite zsh config
curl https://github.com/OpusCapita/infra-workspace/raw/master/zshrc.zsh -H "Cache-Control: no-cache"  -L > ~/.zshrc

# get powerlevel10k config
curl https://github.com/OpusCapita/infra-workspace/raw/master/.p10k.zsh -H "Cache-Control: no-cache"  -L > ~/.p10k.zsh

# preserve your history
[[ ! -f "$HOME/.histfile" ]] && cat "$HOME/.bash_history" > "$HOME/.histfile"

# set as default
sudo usermod --shell /bin/zsh $USER

# activate
exec zsh

echo "Relogin for changes to take effect"
