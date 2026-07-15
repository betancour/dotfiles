# detect.sh — OS, architecture, package manager, shell, privilege detection
# shellcheck shell=sh

# Populate:
#   DF_OS          linux|macos|freebsd|unknown
#   DF_OS_ID       debian|ubuntu|fedora|arch|alpine|rhel|opensuse|macos|…
#   DF_OS_VERSION  raw version string when known
#   DF_ARCH        x86_64|arm64|aarch64|…
#   DF_PKG_MANAGER apt|dnf|yum|pacman|zypper|apk|brew|none
#   DF_SHELL_TYPE  bash|zsh|sh
#   DF_HAS_SUDO    0|1
#   DF_IS_ROOT     0|1
#   DF_KERNEL      uname -s
#   DF_UNAME_M     uname -m

df_detect_os() {
    DF_KERNEL=$(uname -s 2>/dev/null || echo unknown)
    DF_UNAME_M=$(uname -m 2>/dev/null || echo unknown)
    DF_OS=unknown
    DF_OS_ID=unknown
    DF_OS_VERSION=

    case "$DF_KERNEL" in
        Darwin)
            DF_OS=macos
            DF_OS_ID=macos
            DF_OS_VERSION=$(sw_vers -productVersion 2>/dev/null || true)
            ;;
        Linux)
            DF_OS=linux
            if [ -r /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                DF_OS_ID=$(printf '%s' "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')
                DF_OS_VERSION="${VERSION_ID:-}"
            elif [ -r /etc/alpine-release ]; then
                DF_OS_ID=alpine
                DF_OS_VERSION=$(cat /etc/alpine-release 2>/dev/null || true)
            elif [ -r /etc/redhat-release ]; then
                DF_OS_ID=rhel
            fi
            ;;
        FreeBSD)
            DF_OS=freebsd
            DF_OS_ID=freebsd
            DF_OS_VERSION=$(uname -r 2>/dev/null || true)
            ;;
        *)
            DF_OS=unknown
            DF_OS_ID=unknown
            ;;
    esac

    # Normalize architecture labels.
    case "$DF_UNAME_M" in
        x86_64|amd64)   DF_ARCH=x86_64 ;;
        aarch64|arm64)  DF_ARCH=arm64 ;;
        armv7*|armhf)   DF_ARCH=armv7 ;;
        i386|i686)      DF_ARCH=x86 ;;
        *)              DF_ARCH=$DF_UNAME_M ;;
    esac

    log_verbose "OS=$DF_OS id=$DF_OS_ID version=${DF_OS_VERSION:-?} arch=$DF_ARCH kernel=$DF_KERNEL"
}

df_detect_pkg_manager() {
    DF_PKG_MANAGER=none

    # Prefer platform-native managers; brew is available on macOS and Linux.
    case "$DF_OS" in
        macos)
            if df_has_cmd brew; then
                DF_PKG_MANAGER=brew
            fi
            ;;
        linux|freebsd)
            # Order matters: more specific first.
            if df_has_cmd apt-get || df_has_cmd apt; then
                DF_PKG_MANAGER=apt
            elif df_has_cmd dnf; then
                DF_PKG_MANAGER=dnf
            elif df_has_cmd yum; then
                DF_PKG_MANAGER=yum
            elif df_has_cmd pacman; then
                DF_PKG_MANAGER=pacman
            elif df_has_cmd zypper; then
                DF_PKG_MANAGER=zypper
            elif df_has_cmd apk; then
                DF_PKG_MANAGER=apk
            elif df_has_cmd brew; then
                DF_PKG_MANAGER=brew
            elif df_has_cmd pkg && [ "$DF_OS" = "freebsd" ]; then
                DF_PKG_MANAGER=pkg
            fi
            ;;
    esac

    log_verbose "Package manager: $DF_PKG_MANAGER"
}

df_detect_privileges() {
    DF_IS_ROOT=0
    DF_HAS_SUDO=0

    if [ "$(id -u 2>/dev/null || echo 1)" = "0" ]; then
        DF_IS_ROOT=1
        DF_HAS_SUDO=1
        log_verbose "Running as root"
        return 0
    fi

    if df_has_cmd sudo; then
        # Non-interactive probe: do not prompt for password here.
        if sudo -n true >/dev/null 2>&1; then
            DF_HAS_SUDO=1
            log_verbose "Passwordless sudo available"
        else
            # sudo exists; may still work interactively later.
            DF_HAS_SUDO=1
            log_verbose "sudo present (may require password)"
        fi
    else
        log_verbose "No sudo and not root — system package installs will be skipped"
    fi
}

# Detect the user's preferred shell for configuration.
# Priority: explicit arg > $SHELL > runtime shell > available binaries.
df_detect_shell() {
    _df_hint=${1:-}

    if [ -n "$_df_hint" ] && [ "$_df_hint" != "auto" ]; then
        case "$_df_hint" in
            bash|zsh|sh|both|all)
                DF_SHELL_TYPE=$_df_hint
                unset _df_hint
                return 0
                ;;
        esac
    fi

    case "${SHELL:-}" in
        */zsh)  DF_SHELL_TYPE="zsh"; unset _df_hint; return 0 ;;
        */bash) DF_SHELL_TYPE="bash"; unset _df_hint; return 0 ;;
        */sh)   DF_SHELL_TYPE="sh"; unset _df_hint; return 0 ;;
        */dash) DF_SHELL_TYPE="sh"; unset _df_hint; return 0 ;;
    esac

    if [ -n "${ZSH_VERSION:-}" ]; then
        DF_SHELL_TYPE="zsh"
    elif [ -n "${BASH_VERSION:-}" ]; then
        DF_SHELL_TYPE="bash"
    elif df_has_cmd zsh; then
        DF_SHELL_TYPE="zsh"
    elif df_has_cmd bash; then
        DF_SHELL_TYPE="bash"
    else
        DF_SHELL_TYPE="sh"
    fi

    log_verbose "Detected shell: $DF_SHELL_TYPE (SHELL=${SHELL:-unset})"
    unset _df_hint
}

# Run all detectors.
df_detect_all() {
    df_detect_os
    df_detect_pkg_manager
    df_detect_privileges
    df_detect_shell "${1:-auto}"
}

# Human-readable summary for logs / dry-run.
df_print_detection_summary() {
    log_info "Installer version: $DOTFILES_INSTALLER_VERSION"
    log_info "OS:               $DF_OS ($DF_OS_ID ${DF_OS_VERSION:-})"
    log_info "Architecture:     $DF_ARCH"
    log_info "Package manager:  $DF_PKG_MANAGER"
    log_info "Target shell:     $DF_SHELL_TYPE"
    log_info "Root:             $DF_IS_ROOT  sudo: $DF_HAS_SUDO"
    log_info "Dotfiles root:    ${DOTFILES_ROOT:-unset}"
    log_info "Canonical home:   $DOTFILES_CANONICAL_HOME"
}
