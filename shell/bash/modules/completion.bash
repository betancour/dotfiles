# completion.bash — Bash programmable completion

if ! shopt -oq posix 2>/dev/null; then
    for _src in \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /usr/local/etc/bash_completion
    do
        if [ -f "$_src" ]; then
            # shellcheck source=/dev/null
            . "$_src"
            break
        fi
    done
    unset _src
fi

# Git completion (when not already provided by bash-completion)
if ! type -t __git_ps1 >/dev/null 2>&1 && ! type -t _git >/dev/null 2>&1; then
    for _gitc in \
        /opt/homebrew/etc/bash_completion.d/git-completion.bash \
        /usr/share/bash-completion/completions/git \
        /usr/local/etc/bash_completion.d/git-completion.bash \
        /etc/bash_completion.d/git
    do
        if [ -f "$_gitc" ]; then
            # shellcheck source=/dev/null
            . "$_gitc"
            break
        fi
    done
    unset _gitc
fi

# Git prompt helper (optional; our prompt.bash has a native implementation too)
if ! type -t __git_ps1 >/dev/null 2>&1; then
    for _gitp in \
        /opt/homebrew/etc/bash_completion.d/git-prompt.sh \
        /usr/share/git/completion/git-prompt.sh \
        /usr/share/git-core/contrib/completion/git-prompt.sh \
        /usr/local/etc/bash_completion.d/git-prompt.sh
    do
        if [ -f "$_gitp" ]; then
            # shellcheck source=/dev/null
            . "$_gitp"
            break
        fi
    done
    unset _gitp
fi

if [ -n "${__KUBECTL_AVAILABLE:-}" ] && command -v kubectl >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    . <(kubectl completion bash)
fi
