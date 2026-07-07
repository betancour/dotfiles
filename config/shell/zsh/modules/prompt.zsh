# prompt.zsh — Zsh prompt with Git integration

autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git svn hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git*' formats '%b%u%c'
zstyle ':vcs_info:git*' actionformats '%b|%a%u%c'

vcs_prompt() {
    vcs_info
    [[ -z "$vcs_info_msg_0_" ]] && return

    local clean_icon='✓' dirty_icon='●' staged_icon='+' untracked_icon='?'
    local clean_color='%F{green}' dirty_color='%F{red}' staged_color='%F{yellow}'
    local branch_color='%F{cyan}' bracket_color='%F{blue}' reset='%f'
    local git_status="" status_output

    if git rev-parse --git-dir >/dev/null 2>&1; then
        status_output=$(git status --porcelain 2>/dev/null)
        if [[ -n "$status_output" ]]; then
            echo "$status_output" | grep -qE '^[MADRCU]' && git_status="${staged_color}${staged_icon}${reset}"
            echo "$status_output" | grep -qE '^.[MD]|^\?\?' && git_status="${git_status}${dirty_color}${dirty_icon}${reset}"
            echo "$status_output" | grep -q '^\?\?' && git_status="${git_status}${dirty_color}${untracked_icon}${reset}"
        else
            git_status="${clean_color}${clean_icon}${reset}"
        fi
    fi

    echo "${bracket_color}[${branch_color}${vcs_info_msg_0_}${reset} ${git_status}${bracket_color}]${reset}"
}

local user_color='%F{magenta}' host_color='%F{cyan}' path_color='%F{blue}'
local arrow_color='%F{green}' error_color='%F{red}' reset='%f'

PROMPT='
${user_color}%n${reset}@${host_color}%m${reset} ${path_color}[%3~]${reset}$(vcs_prompt) ${path_color}[%D{%H:%M:%S}]${reset}
%(?.${arrow_color}.${error_color})❯${reset} '

RPROMPT='%(?..${error_color}[%?]${reset})'