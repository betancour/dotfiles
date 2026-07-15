# package.sh — package manager abstraction
# shellcheck shell=sh
#
# Provides:
#   df_pkg_update          — refresh package indexes (best-effort)
#   df_pkg_install <pkgs…> — install packages via detected manager
#   df_pkg_is_installed    — check if a *binary* or package is present
#   df_pkg_name            — map logical package → distro package name
#   df_run_privileged      — run command with sudo when needed

# Run a command with elevated privileges when not root.
df_run_privileged() {
    if [ "$DF_IS_ROOT" = "1" ]; then
        "$@"
        return $?
    fi
    if [ "$DF_HAS_SUDO" != "1" ]; then
        log_error "Privilege required but sudo/root unavailable: $*"
        return 1
    fi
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "sudo $*"
        return 0
    fi
    sudo "$@"
}

df_pkg_update() {
    if [ "${DF_PKG_MANAGER:-none}" = "none" ]; then
        log_warn "No package manager detected; skip update"
        return 0
    fi

    log_step "Updating package indexes ($DF_PKG_MANAGER)"

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would update package indexes via $DF_PKG_MANAGER"
        return 0
    fi

    case "$DF_PKG_MANAGER" in
        apt)
            df_run_privileged apt-get update -y || log_warn "apt-get update failed"
            ;;
        dnf)
            df_run_privileged dnf check-update -y || true
            ;;
        yum)
            df_run_privileged yum check-update -y || true
            ;;
        pacman)
            df_run_privileged pacman -Sy --noconfirm || log_warn "pacman -Sy failed"
            ;;
        zypper)
            df_run_privileged zypper refresh || log_warn "zypper refresh failed"
            ;;
        apk)
            df_run_privileged apk update || log_warn "apk update failed"
            ;;
        brew)
            brew update || log_warn "brew update failed"
            ;;
        pkg)
            df_run_privileged pkg update -f || true
            ;;
        *)
            log_warn "Unknown package manager: $DF_PKG_MANAGER"
            ;;
    esac
}

# Install one or more package names (already mapped for the current manager).
df_pkg_install() {
    if [ "$#" -eq 0 ]; then
        return 0
    fi
    if [ "${DF_PKG_MANAGER:-none}" = "none" ]; then
        log_warn "No package manager; cannot install: $*"
        return 1
    fi

    log_info "Installing packages ($DF_PKG_MANAGER): $*"

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would install: $*"
        return 0
    fi

    _df_rc=0
    case "$DF_PKG_MANAGER" in
        apt)
            # DEBIAN_FRONTEND avoids interactive prompts (tzdata, etc.).
            DEBIAN_FRONTEND=noninteractive df_run_privileged \
                apt-get install -y --no-install-recommends "$@" || _df_rc=$?
            ;;
        dnf)
            df_run_privileged dnf install -y "$@" || _df_rc=$?
            ;;
        yum)
            df_run_privileged yum install -y "$@" || _df_rc=$?
            ;;
        pacman)
            df_run_privileged pacman -S --noconfirm --needed "$@" || _df_rc=$?
            ;;
        zypper)
            df_run_privileged zypper install -y "$@" || _df_rc=$?
            ;;
        apk)
            df_run_privileged apk add --no-cache "$@" || _df_rc=$?
            ;;
        brew)
            # brew does not need sudo for formula installs.
            brew install "$@" || _df_rc=$?
            ;;
        pkg)
            df_run_privileged pkg install -y "$@" || _df_rc=$?
            ;;
        *)
            log_error "Unsupported package manager: $DF_PKG_MANAGER"
            _df_rc=1
            ;;
    esac

    if [ "$_df_rc" -eq 0 ]; then
        for _df_p in "$@"; do
            df_journal_record "package|${DF_PKG_MANAGER}|${_df_p}"
        done
        log_success "Installed: $*"
    else
        log_warn "Package install reported errors (rc=$_df_rc): $*"
    fi
    unset _df_rc _df_p
    return 0
}

# Map a logical package name to the distro-specific package.
# Logical names: zoxide fzf ripgrep fd bat eza direnv starship
#                bash-completion zsh-completions git curl wget
#                sc (ShellCheck), eza (or exa), bat (or batcat)
df_pkg_name() {
    _df_logical=$1
    _df_out=

    case "$DF_PKG_MANAGER" in
        brew)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion@2 ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=shellcheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        apt)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd-find ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=shellcheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        dnf|yum)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd-find ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=ShellCheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        pacman)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=shellcheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        zypper)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=ShellCheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        apk)
            case "$_df_logical" in
                zoxide)           _df_out=zoxide ;;
                fzf)              _df_out=fzf ;;
                ripgrep)          _df_out=ripgrep ;;
                fd)               _df_out=fd ;;
                bat)              _df_out=bat ;;
                eza)              _df_out=eza ;;
                direnv)           _df_out=direnv ;;
                starship)         _df_out=starship ;;
                bash-completion)  _df_out=bash-completion ;;
                zsh-completions)  _df_out=zsh-completions ;;
                git)              _df_out=git ;;
                curl)             _df_out=curl ;;
                shellcheck)       _df_out=shellcheck ;;
                *)                _df_out=$_df_logical ;;
            esac
            ;;
        *)
            _df_out=$_df_logical
            ;;
    esac

    printf '%s\n' "$_df_out"
    unset _df_logical _df_out
}

# Check whether a logical tool is available (binary on PATH or known alias).
df_tool_available() {
    _df_tool=$1
    case "$_df_tool" in
        bat)
            df_has_cmd bat || df_has_cmd batcat
            ;;
        fd)
            df_has_cmd fd || df_has_cmd fdfind
            ;;
        ripgrep)
            df_has_cmd rg || df_has_cmd ripgrep
            ;;
        eza)
            df_has_cmd eza || df_has_cmd exa
            ;;
        bash-completion)
            # Presence of completion scripts, not a binary.
            [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ] \
                || [ -f /usr/share/bash-completion/bash_completion ] \
                || [ -f /etc/bash_completion ] \
                || [ -f /usr/local/etc/bash_completion ]
            ;;
        zsh-completions)
            [ -d /opt/homebrew/share/zsh-completions ] \
                || [ -d /usr/share/zsh/site-functions ] \
                || [ -d /usr/local/share/zsh-completions ] \
                || df_has_cmd zsh
            ;;
        *)
            df_has_cmd "$_df_tool"
            ;;
    esac
    _df_rc=$?
    unset _df_tool
    return $_df_rc
}
