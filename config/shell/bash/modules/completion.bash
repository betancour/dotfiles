# completion.bash — Bash programmable completion

if ! shopt -oq posix; then
    for completion_source in \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /usr/local/etc/bash_completion; do
        [[ -f "$completion_source" ]] && source "$completion_source" && break
    done
fi

if [[ -n "${__KUBECTL_AVAILABLE:-}" ]] && command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
fi