# xdg.sh — XDG Base Directory setup

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$USER}"

for _xdg_dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
    [[ -d "$_xdg_dir" ]] || mkdir -p "$_xdg_dir"
done
unset _xdg_dir