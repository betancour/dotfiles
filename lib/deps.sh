# deps.sh — dependency definitions, verification, and installation
# shellcheck shell=sh

# Core CLI tools expected by the shell configuration.
# Format: logical_name (mapped via df_pkg_name)
DF_DEPS_CORE="git curl"

# Recommended modern CLI tools (graceful fallbacks exist without them).
DF_DEPS_TOOLS="zoxide fzf ripgrep fd bat eza direnv"

# Shell completion packages.
DF_DEPS_COMPLETIONS="bash-completion zsh-completions"

# Optional but recommended.
DF_DEPS_OPTIONAL="starship shellcheck"

# Install Homebrew on macOS when missing (official install script).
df_ensure_homebrew() {
    if [ "$DF_OS" != "macos" ]; then
        return 0
    fi
    if df_has_cmd brew; then
        log_verbose "Homebrew already installed"
        return 0
    fi

    log_step "Homebrew not found"
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would install Homebrew"
        return 0
    fi

    if ! df_confirm "Install Homebrew? (required for package management on macOS)"; then
        log_warn "Skipping Homebrew install; dependency installation will be limited"
        return 1
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        log_error "Homebrew installation failed"
        return 1
    }

    # Apple Silicon default prefix.
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if df_has_cmd brew; then
        DF_PKG_MANAGER=brew
        log_success "Homebrew installed"
        return 0
    fi
    log_error "Homebrew installed but brew not on PATH"
    return 1
}

# Install starship via official script when not in package repos.
df_install_starship_fallback() {
    if df_tool_available starship; then
        return 0
    fi
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would install starship via official installer"
        return 0
    fi
    if ! df_has_cmd curl; then
        log_warn "curl missing; cannot install starship fallback"
        return 1
    fi
    log_info "Installing starship via official installer..."
    if curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"; then
        log_success "starship installed to ~/.local/bin"
        df_journal_record "copy|$HOME/.local/bin/starship|starship-installer"
        return 0
    fi
    log_warn "starship fallback install failed"
    return 1
}

# Collect packages that still need installing for a space-separated list.
df_deps_missing() {
    _df_list=$1
    _df_missing=
    for _df_dep in $_df_list; do
        if df_tool_available "$_df_dep"; then
            log_verbose "present: $_df_dep"
        else
            _df_missing="${_df_missing} ${_df_dep}"
        fi
    done
    # shellcheck disable=SC2086
    printf '%s' ${_df_missing# }
    unset _df_list _df_missing _df_dep
}

# Map logical package list → manager package names (unique, space-separated).
df_deps_map_packages() {
    _df_list=$1
    _df_mapped=
    for _df_dep in $_df_list; do
        _df_pkg=$(df_pkg_name "$_df_dep")
        # Skip empty mappings.
        [ -z "$_df_pkg" ] && continue
        # Dedup
        case " $_df_mapped " in
            *" $_df_pkg "*) ;;
            *) _df_mapped="${_df_mapped} ${_df_pkg}" ;;
        esac
    done
    # shellcheck disable=SC2086
    printf '%s' ${_df_mapped# }
    unset _df_list _df_mapped _df_dep _df_pkg
}

# Install a logical package list. Missing tools only; continues on per-pkg failure.
df_deps_install_list() {
    _df_label=$1
    _df_list=$2
    _df_missing=$(df_deps_missing "$_df_list")

    if [ -z "$_df_missing" ]; then
        log_success "$_df_label: all present"
        unset _df_label _df_list _df_missing
        return 0
    fi

    log_info "$_df_label missing: $_df_missing"
    _df_pkgs=$(df_deps_map_packages "$_df_missing")

    if [ -z "$_df_pkgs" ]; then
        log_warn "No packages mapped for: $_df_missing"
        unset _df_label _df_list _df_missing _df_pkgs
        return 0
    fi

    # shellcheck disable=SC2086
    df_pkg_install $_df_pkgs || true

    # Post-check; warn on remaining gaps (non-fatal).
    _df_still=$(df_deps_missing "$_df_list")
    if [ -n "$_df_still" ]; then
        log_warn "Still missing after install attempt: $_df_still"
        # Special-case starship / eza
        case " $_df_still " in
            *" starship "*)
                df_install_starship_fallback || true
                ;;
        esac
    else
        log_success "$_df_label: installed"
    fi
    unset _df_label _df_list _df_missing _df_pkgs _df_still
}

# Full dependency installation pipeline.
df_install_dependencies() {
    if [ "$DOTFILES_SKIP_DEPS" = "1" ]; then
        log_info "Skipping dependency installation (--skip-deps)"
        return 0
    fi

    log_step "Installing dependencies"

    if [ "$DF_OS" = "macos" ]; then
        df_ensure_homebrew || true
        # Re-detect manager after possible brew install.
        df_detect_pkg_manager
    fi

    if [ "${DF_PKG_MANAGER:-none}" = "none" ]; then
        log_warn "No package manager available — install tools manually"
        log_warn "Recommended: zoxide fzf ripgrep fd bat eza direnv starship"
        return 0
    fi

    # System packages typically need privileges (except brew).
    if [ "$DF_PKG_MANAGER" != "brew" ] && [ "$DF_IS_ROOT" != "1" ] && [ "$DF_HAS_SUDO" != "1" ]; then
        log_warn "No privileges for system package installs; skipping deps"
        log_warn "Re-run with sudo-capable user or install packages manually"
        return 0
    fi

    df_pkg_update

    df_deps_install_list "Core" "$DF_DEPS_CORE"
    df_deps_install_list "Tools" "$DF_DEPS_TOOLS"

    # Completions depend on target shell.
    case "${DF_SHELL_TYPE:-auto}" in
        bash)
            df_deps_install_list "Completions" "bash-completion"
            ;;
        zsh)
            df_deps_install_list "Completions" "zsh-completions"
            ;;
        both|all)
            df_deps_install_list "Completions" "$DF_DEPS_COMPLETIONS"
            ;;
        sh)
            log_verbose "POSIX sh: skipping shell-specific completion packages"
            ;;
        *)
            df_deps_install_list "Completions" "$DF_DEPS_COMPLETIONS"
            ;;
    esac

    if [ "$DOTFILES_WITH_OPTIONAL" = "1" ]; then
        df_deps_install_list "Optional" "$DF_DEPS_OPTIONAL"
    fi

    # Debian/Ubuntu: create convenience symlinks for batcat/fdfind when needed.
    df_deps_post_link_helpers

    df_verify_dependencies
}

# Create user-local bin wrappers for Debian-renamed packages.
df_deps_post_link_helpers() {
    _df_local_bin="$HOME/.local/bin"
    df_mkdir_p "$_df_local_bin"

    if df_has_cmd batcat && ! df_has_cmd bat; then
        if [ "$DOTFILES_DRY_RUN" = "1" ]; then
            log_dry "Would link bat -> batcat in $_df_local_bin"
        else
            ln -sf "$(command -v batcat)" "$_df_local_bin/bat"
            log_success "Linked ~/.local/bin/bat -> batcat"
            df_journal_record "symlink|${_df_local_bin}/bat|$(command -v batcat)|"
        fi
    fi

    if df_has_cmd fdfind && ! df_has_cmd fd; then
        if [ "$DOTFILES_DRY_RUN" = "1" ]; then
            log_dry "Would link fd -> fdfind in $_df_local_bin"
        else
            ln -sf "$(command -v fdfind)" "$_df_local_bin/fd"
            log_success "Linked ~/.local/bin/fd -> fdfind"
            df_journal_record "symlink|${_df_local_bin}/fd|$(command -v fdfind)|"
        fi
    fi
    unset _df_local_bin
}

# Print a dependency status table.
df_verify_dependencies() {
    log_step "Verifying dependencies"
    _df_all="$DF_DEPS_CORE $DF_DEPS_TOOLS $DF_DEPS_COMPLETIONS"
    if [ "$DOTFILES_WITH_OPTIONAL" = "1" ]; then
        _df_all="$_df_all $DF_DEPS_OPTIONAL"
    fi

    _df_ok=0
    _df_miss=0
    for _df_dep in $_df_all; do
        if df_tool_available "$_df_dep"; then
            log_success "$_df_dep"
            _df_ok=$((_df_ok + 1))
        else
            log_warn "$_df_dep (missing — aliases will fall back)"
            _df_miss=$((_df_miss + 1))
        fi
    done
    log_info "Dependency check: ${_df_ok} present, ${_df_miss} missing"
    df_manifest_add deps_ok "$_df_ok"
    df_manifest_add deps_missing "$_df_miss"
    unset _df_all _df_ok _df_miss _df_dep
}

# Minimum version checks for critical tools (warn only).
df_version_checks() {
    log_step "Version checks"

    if df_has_cmd git; then
        _df_v=$(git --version 2>/dev/null | awk '{print $3}')
        log_info "git $_df_v"
        # Require git >= 2.0 for include.path etc.
        _df_major=$(printf '%s' "$_df_v" | cut -d. -f1)
        if [ "${_df_major:-0}" -lt 2 ] 2>/dev/null; then
            log_warn "git $_df_v is old; recommend >= 2.x"
        fi
    else
        log_warn "git not found"
    fi

    if df_has_cmd bash; then
        log_info "bash $(bash --version 2>/dev/null | head -n1)"
    fi
    if df_has_cmd zsh; then
        log_info "zsh $(zsh --version 2>/dev/null)"
    fi
    if df_has_cmd starship; then
        log_info "starship $(starship --version 2>/dev/null | head -n1)"
    fi
    unset _df_v _df_major
}
