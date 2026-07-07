# xdg.sh — XDG Base Directory setup

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# Only set XDG_RUNTIME_DIR when the system has not already provided one.
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    if [[ -d "/tmp/runtime-${UID:-$(id -u)}" ]]; then
        export XDG_RUNTIME_DIR="/tmp/runtime-${UID:-$(id -u)}"
    fi
fi

for _xdg_dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
    [[ -d "$_xdg_dir" ]] || mkdir -p "$_xdg_dir"
    chmod 700 "$_xdg_dir" 2>/dev/null || true
done
unset _xdg_dir