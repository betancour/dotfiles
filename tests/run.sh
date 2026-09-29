#!/usr/bin/env bash
# Behavioral contract for the dotfiles. See tests/README.md.
# Bash 3.2 is enough to run this file.

set +e
set -u

_df_src=${BASH_SOURCE[0]}
while [ -L "$_df_src" ]; do
    _df_dir=$(cd -P "$(dirname "$_df_src")" && pwd)
    _df_src=$(readlink "$_df_src")
    case $_df_src in
        /*) ;;
        *) _df_src=$_df_dir/$_df_src ;;
    esac
done
DF_ROOT=$(cd -P "$(dirname "$_df_src")/.." && pwd)
DF_LIB=$DF_ROOT/tests/lib
DF_BASE=$DF_ROOT/tests/baseline
unset _df_src _df_dir

# shellcheck source=lib/harness.sh
. "$DF_LIB/harness.sh"
# shellcheck source=lib/sandbox.sh
. "$DF_LIB/sandbox.sh"
# shellcheck source=lib/invoke.sh
. "$DF_LIB/invoke.sh"
# shellcheck source=lib/baseline.sh
. "$DF_LIB/baseline.sh"
# shellcheck source=lib/cases.sh
. "$DF_LIB/cases.sh"

DF_UPDATE=0
while [ $# -gt 0 ]; do
    case $1 in
        --update-baseline) DF_UPDATE=1 ;;
        -h|--help)
            df_usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n\n' "$1" >&2
            df_usage >&2
            exit 2
            ;;
    esac
    shift
done

DF_ITERS=${DOTFILES_TEST_ITERS:-10}
DF_RATIO=${DOTFILES_TEST_PERF_RATIO:-1.5}
DF_SLACK=${DOTFILES_TEST_PERF_SLACK_MS:-25}
case $DF_ITERS in
    ''|*[!0-9]*) DF_ITERS=10 ;;
esac
if [ "$DF_ITERS" -lt 1 ]; then
    DF_ITERS=1
fi
DF_TIMEOUT=${DOTFILES_TEST_TIMEOUT:-30}
DF_PASSES=0
DF_FAILS=0

if [ -x /bin/zsh ]; then
    DF_ZSH=/bin/zsh
else
    DF_ZSH=$(command -v zsh || true)
fi
if [ -x /opt/homebrew/bin/bash ]; then
    DF_BASH=/opt/homebrew/bin/bash
elif [ -x /usr/local/bin/bash ]; then
    DF_BASH=/usr/local/bin/bash
elif [ -x /home/linuxbrew/.linuxbrew/bin/bash ]; then
    DF_BASH=/home/linuxbrew/.linuxbrew/bin/bash
else
    DF_BASH=$(command -v bash || true)
fi
DF_SH=/bin/sh
SB_USER=$(id -un)
SB_UID=$(id -u)

DF_WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-harness.XXXXXX")
trap 'sb_destroy; rm -rf "$DF_WORK"' EXIT
: > "$DF_WORK/summary"

# Harness locale only. Child shells get the env file, which leaves LC_ALL unset.
export LC_ALL=C

printf 'DOTFILES TEST SUITE\n\n'
if [ "$DF_UPDATE" = 1 ]; then
    printf 'Updating the baseline from this run, then checking it.\n\n'
fi

df_safety_status
df_section_repository
df_section_syntax_bash
df_section_syntax_zsh
df_section_syntax_sh

if [ -z "$DF_ZSH" ] || [ ! -x "$DF_ZSH" ]; then
    df_section_begin "Shell execution"
    df_fail "zsh is not installed"
    df_section_end
elif ! command -v python3 >/dev/null 2>&1; then
    df_section_begin "Shell execution"
    df_fail "python3 is required to launch shells under a terminal"
    df_section_end
else
    printf 'Launching shells and recording startup...\n\n'
    sb_create
    df_capture_all
    if [ "$DF_UPDATE" = 1 ]; then
        df_publish_baselines
    fi
    df_section_zsh_noninteractive
    df_section_zsh_interactive
    df_section_zsh_login
    df_section_bash_noninteractive
    df_section_bash_interactive
    df_section_bash_login
    df_section_path
    df_section_env
    df_section_alias
    df_section_functions
    df_section_tools
    df_section_tty
    df_section_noninteractive
    df_section_banner
    df_section_ansi
    df_section_launchctl
    df_section_missing
    df_section_perf
fi

df_section_isolation

if [ -s "$DF_WORK/summary" ]; then
    printf '\n'
    cat "$DF_WORK/summary"
fi
printf '\nPassed: %s\nFailed: %s\n' "$DF_PASSES" "$DF_FAILS"
if [ "$DF_FAILS" -eq 0 ]; then
    printf 'RESULT: PASS\n'
    exit 0
fi
printf 'RESULT: FAIL\n'
exit 1
