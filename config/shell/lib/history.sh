# history.sh — secret-aware history and secure file permissions

[[ -n "${DOTFILES_HISTORY_LOADED:-}" ]] && return 0
DOTFILES_HISTORY_LOADED=1

# Patterns for commands that must never be written to history.
DOTFILES_HIST_SECRET_PATTERN='(password|PASSWORD|TOKEN|SECRET|API_KEY|api_key|credential|Bearer |AWS_|OPENAI_|GITHUB_TOKEN|DATABASE_PASSWORD|mysql -p|postgres://|redis://)'

dotfiles_history_ignore_patterns() {
    # Bash HISTIGNORE (colon-separated globs).
    printf '%s' 'ls:cd:cd -:pwd:exit:date:* --help:history:clear:*password*:*PASSWORD*:*TOKEN*:*SECRET*:*API_KEY*:*api_key*:*credential*:*Bearer*:*AWS_*:*OPENAI_*:*GITHUB_TOKEN*'
}

dotfiles_secure_history_file() {
    local histfile="${1:-${HISTFILE:-}}"
    local histdir

    [[ -z "$histfile" ]] && return 0

    histdir="$(dirname "$histfile")"
    [[ -d "$histdir" ]] || mkdir -p "$histdir"
    chmod 700 "$histdir" 2>/dev/null || true

    if [[ -f "$histfile" ]]; then
        chmod 600 "$histfile" 2>/dev/null || true
    elif [[ ! -e "$histfile" ]]; then
        : > "$histfile"
        chmod 600 "$histfile" 2>/dev/null || true
    fi
}

dotfiles_secure_history_backup() {
    local backup="$1"
    [[ -f "$backup" ]] && chmod 600 "$backup" 2>/dev/null || true
}

dotfiles_clear_secret_env() {
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN \
        GITHUB_TOKEN OPENAI_API_KEY ANTHROPIC_API_KEY DATABASE_PASSWORD \
        NPM_TOKEN DOCKER_PASSWORD KUBECONFIG 2>/dev/null || true
}