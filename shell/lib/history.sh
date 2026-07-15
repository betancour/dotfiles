# history.sh — secret-aware history helpers and secure file permissions

[ -n "${DOTFILES_HISTORY_LOADED:-}" ] && return 0
DOTFILES_HISTORY_LOADED=1

# Patterns for commands that must never be written to history.
DOTFILES_HIST_SECRET_PATTERN='(password|PASSWORD|TOKEN|SECRET|API_KEY|api_key|credential|Bearer |AWS_|OPENAI_|GITHUB_TOKEN|DATABASE_PASSWORD|mysql -p|postgres://|redis://)'

# Bash HISTIGNORE (colon-separated globs).
dotfiles_history_ignore_patterns() {
    printf '%s' 'ls:cd:cd -:pwd:exit:date:* --help:history:clear:*password*:*PASSWORD*:*TOKEN*:*SECRET*:*API_KEY*:*api_key*:*credential*:*Bearer*:*AWS_*:*OPENAI_*:*GITHUB_TOKEN*'
}

dotfiles_secure_history_file() {
    _hf="${1:-${HISTFILE:-}}"
    [ -z "$_hf" ] && unset _hf && return 0

    _hd="$(dirname "$_hf")"
    [ -d "$_hd" ] || mkdir -p "$_hd"
    chmod 700 "$_hd" 2>/dev/null || true

    if [ -f "$_hf" ]; then
        chmod 600 "$_hf" 2>/dev/null || true
    elif [ ! -e "$_hf" ]; then
        : > "$_hf"
        chmod 600 "$_hf" 2>/dev/null || true
    fi
    unset _hf _hd
}

dotfiles_secure_history_backup() {
    [ -f "$1" ] && chmod 600 "$1" 2>/dev/null || true
}

dotfiles_clear_secret_env() {
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN \
        GITHUB_TOKEN OPENAI_API_KEY ANTHROPIC_API_KEY DATABASE_PASSWORD \
        NPM_TOKEN DOCKER_PASSWORD 2>/dev/null || true
}
