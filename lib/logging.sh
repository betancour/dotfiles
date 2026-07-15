# logging.sh — colored status messages, verbose mode, file logging
# shellcheck shell=sh

# Resolve color usage: auto | always | never
_df_setup_colors() {
    _df_use_color=0
    case "${DOTFILES_COLOR:-auto}" in
        always) _df_use_color=1 ;;
        never)  _df_use_color=0 ;;
        *)
            if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
                _df_use_color=1
            fi
            ;;
    esac

    if [ "$_df_use_color" = "1" ]; then
        C_INFO=$(printf '\033[34m')
        C_OK=$(printf '\033[32m')
        C_WARN=$(printf '\033[33m')
        C_ERR=$(printf '\033[31m')
        C_DIM=$(printf '\033[2m')
        C_BOLD=$(printf '\033[1m')
        C_DRY=$(printf '\033[36m')
        C_RST=$(printf '\033[0m')
    else
        C_INFO='' C_OK='' C_WARN='' C_ERR='' C_DIM='' C_BOLD='' C_DRY='' C_RST=''
    fi
    unset _df_use_color
}

_df_setup_colors

# Append a line to the log file when available (best-effort).
_df_log_to_file() {
    _df_level=$1
    shift
    if [ -n "${DOTFILES_LOG_FILE:-}" ]; then
        # Ensure parent exists; ignore failures in restricted environments.
        mkdir -p "$(dirname "$DOTFILES_LOG_FILE")" 2>/dev/null || true
        printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo '?')" "$_df_level" "$*" >>"$DOTFILES_LOG_FILE" 2>/dev/null || true
    fi
    unset _df_level
}

log_info() {
    printf '%s[INFO]%s %s\n' "$C_INFO" "$C_RST" "$*"
    _df_log_to_file INFO "$@"
}

log_success() {
    printf '%s[OK]%s %s\n' "$C_OK" "$C_RST" "$*"
    _df_log_to_file OK "$@"
}

log_warn() {
    printf '%s[WARN]%s %s\n' "$C_WARN" "$C_RST" "$*" >&2
    _df_log_to_file WARN "$@"
}

log_error() {
    printf '%s[ERROR]%s %s\n' "$C_ERR" "$C_RST" "$*" >&2
    _df_log_to_file ERROR "$@"
}

log_verbose() {
    if [ "${DOTFILES_VERBOSE:-0}" = "1" ]; then
        printf '%s[DEBUG]%s %s\n' "$C_DIM" "$C_RST" "$*"
        _df_log_to_file DEBUG "$@"
    fi
}

log_dry() {
    printf '%s[DRY-RUN]%s %s\n' "$C_DRY" "$C_RST" "$*"
    _df_log_to_file DRY-RUN "$@"
}

log_step() {
    printf '\n%s==>%s %s%s%s\n' "$C_BOLD" "$C_RST" "$C_BOLD" "$*" "$C_RST"
    _df_log_to_file STEP "$@"
}

log_header() {
    printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RST"
    printf '%s\n' "----------------------------------------"
    _df_log_to_file HEADER "$@"
}

# Fatal: log and exit.
die() {
    log_error "$@"
    exit 1
}
