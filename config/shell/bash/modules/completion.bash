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

if [ -n "${__KUBECTL_AVAILABLE:-}" ] && command -v kubectl >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    . <(kubectl completion bash)
fi
