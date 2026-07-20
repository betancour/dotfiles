# shell_install.sh — install shell, git, vim configuration
# shellcheck shell=sh

SHELL_CONFIG_DIR="${DOTFILES_ROOT}/shell"

# Syntax-check shell entry points before linking (non-fatal on missing binary).
df_validate_zsh_config() {
    if ! df_has_cmd zsh; then
        log_warn "zsh not installed; skipping syntax check"
        return 0
    fi
    for _df_f in \
        "${SHELL_CONFIG_DIR}/zsh/.zshenv" \
        "${SHELL_CONFIG_DIR}/zsh/.zprofile" \
        "${SHELL_CONFIG_DIR}/zsh/.zshrc" \
        "${SHELL_CONFIG_DIR}/zsh/.zlogin" \
        "${SHELL_CONFIG_DIR}/zsh/.zlogout"
    do
        [ -f "$_df_f" ] || continue
        if ! zsh -n "$_df_f"; then
            log_error "Zsh syntax error in $_df_f"
            unset _df_f
            return 1
        fi
    done
    log_verbose "Zsh syntax OK"
    unset _df_f
    return 0
}

df_validate_bash_config() {
    if ! df_has_cmd bash; then
        log_warn "bash not installed; skipping syntax check"
        return 0
    fi
    for _df_f in \
        "${SHELL_CONFIG_DIR}/bash/.bash_env" \
        "${SHELL_CONFIG_DIR}/bash/.bash_profile" \
        "${SHELL_CONFIG_DIR}/bash/.bashrc" \
        "${SHELL_CONFIG_DIR}/bash/.bash_login" \
        "${SHELL_CONFIG_DIR}/bash/.bash_logout"
    do
        [ -f "$_df_f" ] || continue
        if ! bash -n "$_df_f"; then
            log_error "Bash syntax error in $_df_f"
            unset _df_f
            return 1
        fi
    done
    log_verbose "Bash syntax OK"
    unset _df_f
    return 0
}

df_validate_sh_config() {
    for _df_f in \
        "${SHELL_CONFIG_DIR}/sh/.profile" \
        "${SHELL_CONFIG_DIR}/sh/modules/tools.sh"
    do
        [ -f "$_df_f" ] || continue
        if df_has_cmd sh; then
            # Best-effort: many sh don't support -n the same way; use bash -n if available.
            if df_has_cmd bash; then
                bash -n "$_df_f" || {
                    log_error "sh config syntax error in $_df_f"
                    unset _df_f
                    return 1
                }
            fi
        fi
    done
    log_verbose "POSIX sh config syntax OK"
    unset _df_f
    return 0
}

# --- full symlink installers ---

df_install_zsh_symlinks() {
    log_step "Installing Zsh configuration (symlinks)"
    df_validate_zsh_config || return 1

    df_link_file "${SHELL_CONFIG_DIR}/zsh/.zshenv"   "${HOME}/.zshenv"
    df_link_file "${SHELL_CONFIG_DIR}/zsh/.zprofile" "${HOME}/.zprofile"
    df_link_file "${SHELL_CONFIG_DIR}/zsh/.zshrc"    "${HOME}/.zshrc"
    df_link_file "${SHELL_CONFIG_DIR}/zsh/.zlogin"   "${HOME}/.zlogin"
    df_link_file "${SHELL_CONFIG_DIR}/zsh/.zlogout"  "${HOME}/.zlogout"
    df_link_file "${SHELL_CONFIG_DIR}/.zaliases"     "${HOME}/.zaliases"
    df_link_file "${SHELL_CONFIG_DIR}/.zfunctions"   "${HOME}/.zfunctions"

    df_install_template \
        "${DOTFILES_ROOT}/config/terminal/.zshrc.local.template" \
        "${HOME}/.zshrc.local"

    df_manifest_add shell_zsh installed
}

df_install_bash_symlinks() {
    log_step "Installing Bash configuration (symlinks)"
    df_validate_bash_config || return 1

    df_link_file "${SHELL_CONFIG_DIR}/bash/.bash_env"     "${HOME}/.bash_env"
    df_link_file "${SHELL_CONFIG_DIR}/bash/.bash_profile" "${HOME}/.bash_profile"
    df_link_file "${SHELL_CONFIG_DIR}/bash/.bashrc"       "${HOME}/.bashrc"
    df_link_file "${SHELL_CONFIG_DIR}/bash/.bash_login"   "${HOME}/.bash_login"
    df_link_file "${SHELL_CONFIG_DIR}/bash/.bash_logout"  "${HOME}/.bash_logout"
    # Shared alias/function entry points (same files used by Zsh)
    df_link_file "${SHELL_CONFIG_DIR}/.zaliases"          "${HOME}/.zaliases"
    df_link_file "${SHELL_CONFIG_DIR}/.zfunctions"        "${HOME}/.zfunctions"

    df_install_template \
        "${DOTFILES_ROOT}/config/terminal/.bashrc.local.template" \
        "${HOME}/.bashrc.local"

    df_manifest_add shell_bash installed
}

df_install_sh_symlinks() {
    log_step "Installing POSIX sh configuration (symlinks)"
    df_validate_sh_config || return 1

    # Only link .profile when missing or force; many systems already have one.
    if [ -L "${HOME}/.profile" ] || [ ! -e "${HOME}/.profile" ] || [ "$DOTFILES_FORCE" = "1" ]; then
        df_link_file "${SHELL_CONFIG_DIR}/sh/.profile" "${HOME}/.profile"
    else
        log_warn "\$HOME/.profile exists; use --force to replace or --append to inject"
        if [ "$DOTFILES_APPEND" = "1" ]; then
            df_append_managed_source \
                "${HOME}/.profile" \
                "${SHELL_CONFIG_DIR}/sh/.profile" \
                "POSIX sh dotfiles"
        fi
    fi

    df_manifest_add shell_sh installed
}

# --- append-mode installers ---

df_install_zsh_append() {
    log_step "Installing Zsh configuration (append managed blocks)"
    df_validate_zsh_config || return 1

    _df_loader="${DOTFILES_STATE_DIR}/loaders/zshrc.loader"
    df_write_loader "$_df_loader" zsh
    df_append_managed_source "${HOME}/.zshrc" "$_df_loader" "zshrc"

    # Env for non-interactive / early startup
    _df_env_loader="${DOTFILES_STATE_DIR}/loaders/zshenv.loader"
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would write zshenv loader"
    else
        mkdir -p "$(dirname "$_df_env_loader")"
        cat >"$_df_env_loader" <<EOF
# Generated by dotfiles installer
export DOTFILES_DIR="${DOTFILES_ROOT}"
[ -r "${SHELL_CONFIG_DIR}/zsh/.zshenv" ] && . "${SHELL_CONFIG_DIR}/zsh/.zshenv"
EOF
        df_journal_record "copy|${_df_env_loader}|generated"
    fi
    df_append_managed_source "${HOME}/.zshenv" "$_df_env_loader" "zshenv"

    df_install_template \
        "${DOTFILES_ROOT}/config/terminal/.zshrc.local.template" \
        "${HOME}/.zshrc.local"

    df_manifest_add shell_zsh append
    unset _df_loader _df_env_loader
}

df_install_bash_append() {
    log_step "Installing Bash configuration (append managed blocks)"
    df_validate_bash_config || return 1

    _df_loader="${DOTFILES_STATE_DIR}/loaders/bashrc.loader"
    df_write_loader "$_df_loader" bash
    df_append_managed_source "${HOME}/.bashrc" "$_df_loader" "bashrc"

    _df_prof_loader="${DOTFILES_STATE_DIR}/loaders/bash_profile.loader"
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would write bash_profile loader"
    else
        mkdir -p "$(dirname "$_df_prof_loader")"
        cat >"$_df_prof_loader" <<EOF
# Generated by dotfiles installer
export DOTFILES_DIR="${DOTFILES_ROOT}"
[ -r "${SHELL_CONFIG_DIR}/bash/.bash_profile" ] && . "${SHELL_CONFIG_DIR}/bash/.bash_profile"
EOF
        df_journal_record "copy|${_df_prof_loader}|generated"
    fi
    df_append_managed_source "${HOME}/.bash_profile" "$_df_prof_loader" "bash_profile"

    df_install_template \
        "${DOTFILES_ROOT}/config/terminal/.bashrc.local.template" \
        "${HOME}/.bashrc.local"

    df_manifest_add shell_bash append
    unset _df_loader _df_prof_loader
}

df_install_sh_append() {
    log_step "Installing POSIX sh configuration (append managed block)"
    df_validate_sh_config || return 1

    _df_loader="${DOTFILES_STATE_DIR}/loaders/profile.loader"
    df_write_loader "$_df_loader" sh
    df_append_managed_source "${HOME}/.profile" "$_df_loader" "profile"

    df_manifest_add shell_sh append
    unset _df_loader
}

# Dispatch shell install based on mode.
df_install_shell() {
    _df_which=$1
    SHELL_CONFIG_DIR="${DOTFILES_ROOT}/shell"

    case "$_df_which" in
        zsh)
            if [ "$DOTFILES_APPEND" = "1" ]; then
                df_install_zsh_append
            else
                df_install_zsh_symlinks
            fi
            ;;
        bash)
            if [ "$DOTFILES_APPEND" = "1" ]; then
                df_install_bash_append
            else
                df_install_bash_symlinks
            fi
            ;;
        sh)
            if [ "$DOTFILES_APPEND" = "1" ]; then
                df_install_sh_append
            else
                df_install_sh_symlinks
            fi
            ;;
        both)
            if [ "$DOTFILES_APPEND" = "1" ]; then
                df_install_zsh_append
                df_install_bash_append
            else
                df_install_zsh_symlinks
                df_install_bash_symlinks
            fi
            ;;
        all)
            if [ "$DOTFILES_APPEND" = "1" ]; then
                df_install_zsh_append
                df_install_bash_append
                df_install_sh_append
            else
                df_install_zsh_symlinks
                df_install_bash_symlinks
                df_install_sh_symlinks
            fi
            ;;
        *)
            log_error "Unknown shell target: $_df_which"
            unset _df_which
            return 1
            ;;
    esac
    unset _df_which
}

# Git configuration.
df_install_git() {
    log_step "Installing Git configuration"

    # Prefer git/ tree if populated; fall back to repo-root .gitconfig.
    _df_gc=
    if [ -f "${DOTFILES_ROOT}/git/gitconfig" ]; then
        _df_gc="${DOTFILES_ROOT}/git/gitconfig"
    elif [ -f "${DOTFILES_ROOT}/.gitconfig" ]; then
        _df_gc="${DOTFILES_ROOT}/.gitconfig"
    fi

    if [ -n "$_df_gc" ]; then
        df_link_file "$_df_gc" "${HOME}/.gitconfig"
    else
        log_verbose "No gitconfig found in repository"
    fi

    _df_gi=
    if [ -f "${DOTFILES_ROOT}/git/gitignore_global" ]; then
        _df_gi="${DOTFILES_ROOT}/git/gitignore_global"
    elif [ -f "${DOTFILES_ROOT}/.gitignore" ]; then
        # Only link if it looks like a global ignores file — use git/ preferred.
        :
    fi
    if [ -n "$_df_gi" ]; then
        df_link_file "$_df_gi" "${HOME}/.gitignore_global"
    fi

    _df_tpl="${DOTFILES_ROOT}/.gitconfig.local.template"
    [ -f "${DOTFILES_ROOT}/git/gitconfig.local.template" ] && \
        _df_tpl="${DOTFILES_ROOT}/git/gitconfig.local.template"

    df_install_template "$_df_tpl" "${HOME}/.gitconfig.local"
    if [ -f "${HOME}/.gitconfig.local" ] && [ "$DOTFILES_DRY_RUN" != "1" ]; then
        chmod 600 "${HOME}/.gitconfig.local" 2>/dev/null || true
    fi

    df_manifest_add gitconfig installed
    unset _df_gc _df_gi _df_tpl
}

# Vim configuration.
df_install_vim() {
    log_step "Installing Vim configuration"

    _df_vimrc=
    if [ -f "${DOTFILES_ROOT}/vim/vimrc" ]; then
        _df_vimrc="${DOTFILES_ROOT}/vim/vimrc"
    elif [ -f "${DOTFILES_ROOT}/.vimrc" ]; then
        _df_vimrc="${DOTFILES_ROOT}/.vimrc"
    elif [ -f "${DOTFILES_ROOT}/config/terminal/.vimrc" ]; then
        _df_vimrc="${DOTFILES_ROOT}/config/terminal/.vimrc"
    fi

    if [ -n "$_df_vimrc" ]; then
        df_link_file "$_df_vimrc" "${HOME}/.vimrc"
        df_manifest_add vimrc installed
    else
        log_verbose "No vimrc found"
    fi
    unset _df_vimrc
}

# Starship config if present.
df_install_starship_config() {
    _df_src="${DOTFILES_ROOT}/config/starship/starship.toml"
    if [ ! -f "$_df_src" ]; then
        log_verbose "No starship.toml in repo; skip"
        unset _df_src
        return 0
    fi
    log_step "Installing Starship configuration"
    df_mkdir_p "${HOME}/.config"
    df_link_file "$_df_src" "${HOME}/.config/starship.toml"
    unset _df_src
}

# Alacritty config directory (symlink whole tree into XDG config).
# Note: df_link_file unsets its own _df_src/_df_dest; use distinct names so
# post-link validation works under set -u.
df_install_alacritty_config() {
    _df_alacritty_src="${DOTFILES_ROOT}/config/alacritty"
    _df_alacritty_dest="${HOME}/.config/alacritty"
    if [ ! -d "$_df_alacritty_src" ] || [ ! -f "${_df_alacritty_src}/alacritty.toml" ]; then
        log_verbose "No alacritty config in repo; skip"
        unset _df_alacritty_src _df_alacritty_dest
        return 0
    fi
    log_step "Installing Alacritty configuration"
    df_mkdir_p "${HOME}/.config"
    df_link_file "$_df_alacritty_src" "$_df_alacritty_dest" || {
        log_warn "Alacritty config not linked (existing tree at $_df_alacritty_dest; use --force)"
        unset _df_alacritty_src _df_alacritty_dest
        return 0
    }
    if df_has_cmd python3 && [ "$DOTFILES_DRY_RUN" != "1" ]; then
        if python3 - "$_df_alacritty_src" <<'PY'
import sys, tomllib
from pathlib import Path
root = Path(sys.argv[1])
for p in sorted(root.rglob("*.toml")):
    tomllib.load(p.open("rb"))
PY
        then
            log_verbose "Alacritty TOML syntax OK"
        else
            log_warn "Alacritty TOML syntax check failed"
        fi
    fi
    unset _df_alacritty_src _df_alacritty_dest
}
