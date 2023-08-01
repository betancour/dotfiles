if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi

export ZSH_COMPDUMP="$HOME/.cache/zcompdump"

if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

export PATH="$HOME/bin:/usr/local/bin:$PATH"
export TERM="$TERM"
export LANG="en_US.UTF-8"
export GIT_HOME="$HOME/.git"
export PATH="$PATH:$HOME/opt/python/3.11.4/bin"
export MAVEN_HOME="$HOME/.java/apache-maven-3.9.3"
export GRADLE_HOME="$HOME/.java/gradle-8.2"
export PATH="$PATH:$MAVEN_HOME/bin:$GRADLE_HOME/bin"

eval "$(/opt/homebrew/bin/brew shellenv)"
