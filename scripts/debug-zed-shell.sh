#!/bin/bash

# Zed Shell Debug Helper
# ======================
# This script helps diagnose shell issues that affect Zed editor
# Run this script to check for common problems with shell configuration

echo "🔍 Zed Shell Environment Debugger"
echo "=================================="
echo

# Check shell type and version
echo "📊 Shell Information:"
echo "  Current shell: $SHELL"
echo "  Shell version: $($SHELL --version 2>/dev/null | head -n1)"
echo "  SHLVL: $SHLVL"
echo "  Interactive: $([[ $- == *i* ]] && echo "yes" || echo "no")"
echo "  Login shell: $([[ -o login ]] 2>/dev/null && echo "yes" || echo "no")"
echo

# Check environment variables that might affect Zed
echo "🌐 Environment Variables:"
echo "  TERM: $TERM"
echo "  TERM_PROGRAM: $TERM_PROGRAM"
echo "  ZED: $ZED"
echo "  ZELLIJ: $ZELLIJ"
echo "  EDITOR: $EDITOR"
echo "  VISUAL: $VISUAL"
echo

# Check PATH for duplicates
echo "🛤️  PATH Analysis:"
IFS=':' read -ra PATH_ARRAY <<< "$PATH"
declare -A path_count
duplicates=()

for path in "${PATH_ARRAY[@]}"; do
    ((path_count["$path"]++))
    if [[ ${path_count["$path"]} -gt 1 ]]; then
        duplicates+=("$path")
    fi
done

if [[ ${#duplicates[@]} -gt 0 ]]; then
    echo "  ⚠️  Duplicate PATH entries found:"
    for dup in "${duplicates[@]}"; do
        echo "    - $dup (appears ${path_count[$dup]} times)"
    done
else
    echo "  ✅ No duplicate PATH entries found"
fi
echo

# Check for problematic shell configurations
echo "🔧 Shell Configuration Issues:"

# Check for Zellij auto-start
if grep -q "exec zellij" ~/.zshrc 2>/dev/null; then
    echo "  ⚠️  Found 'exec zellij' in .zshrc - this can break Zed's shell processes"
    if grep -q "ZED.*return" ~/.zshrc 2>/dev/null; then
        echo "    ✅ But found ZED check - should be okay"
    else
        echo "    ❌ No ZED check found - may cause issues"
    fi
else
    echo "  ✅ No problematic Zellij auto-start found"
fi

# Check for other exec commands in shell configs
exec_commands=$(grep -n "exec " ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin 2>/dev/null | grep -v "exec zellij")
if [[ -n "$exec_commands" ]]; then
    echo "  ⚠️  Found other 'exec' commands in shell configs:"
    echo "$exec_commands" | sed 's/^/    /'
else
    echo "  ✅ No other problematic exec commands found"
fi

# Check for commands that might hang
problematic_commands=("zellij" "tmux attach" "screen -r")
for cmd in "${problematic_commands[@]}"; do
    if grep -q "$cmd" ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin 2>/dev/null; then
        echo "  ⚠️  Found '$cmd' in shell config - might cause hanging"
    fi
done
echo

# Check Zed-specific issues
echo "🎯 Zed-Specific Checks:"

# Check Zed settings
if [[ -f ~/.config/zed/settings.json ]]; then
    echo "  ✅ Zed settings file exists"

    # Check for JSON syntax errors
    if command -v jq >/dev/null 2>&1; then
        if jq empty ~/.config/zed/settings.json 2>/dev/null; then
            echo "  ✅ Zed settings JSON is valid"
        else
            echo "  ❌ Zed settings JSON has syntax errors"
            echo "    Run: jq . ~/.config/zed/settings.json"
        fi
    else
        # Basic check without jq
        if grep -q "^{" ~/.config/zed/settings.json && grep -q "}$" ~/.config/zed/settings.json; then
            echo "  ✅ Zed settings appears to be JSON format"
        else
            echo "  ⚠️  Zed settings might not be valid JSON (install 'jq' for better validation)"
        fi
    fi

    # Check terminal shell configuration
    shell_config=$(grep -A3 -B1 '"shell"' ~/.config/zed/settings.json 2>/dev/null)
    if [[ -n "$shell_config" ]]; then
        echo "  📋 Terminal shell config in Zed:"
        echo "$shell_config" | sed 's/^/    /'
    fi
else
    echo "  ⚠️  No Zed settings file found at ~/.config/zed/settings.json"
fi
echo

# Check for common tools
echo "🛠️  Tool Availability:"
tools=("git" "node" "npm" "nvim" "vim" "zellij" "fzf" "rg" "fd")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✅ $tool: $(which "$tool")"
    else
        echo "  ❌ $tool: not found"
    fi
done
echo

# Test shell startup performance
echo "⚡ Shell Startup Performance:"
echo "  Testing shell startup time..."

# Time a non-interactive shell
time_output=$( { time $SHELL -c 'exit' ; } 2>&1 )
real_time=$(echo "$time_output" | grep real | awk '{print $2}')
echo "  Non-interactive shell startup: $real_time"

# Time an interactive shell
time_output=$( { time $SHELL -i -c 'exit' ; } 2>&1 )
real_time=$(echo "$time_output" | grep real | awk '{print $2}')
echo "  Interactive shell startup: $real_time"
echo

# Recommendations
echo "💡 Recommendations:"
echo "1. If you see 'exec zellij' issues, make sure your .zshrc excludes Zed processes"
echo "2. Fix any JSON syntax errors in Zed settings"
echo "3. Remove duplicate PATH entries for better performance"
echo "4. Consider using 'zellij attach -c' instead of 'exec zellij' for auto-attach"
echo "5. Set ZED=1 environment variable in Zed terminal settings"
echo

# Quick fix suggestions
echo "🔧 Quick Fixes:"
if [[ ${#duplicates[@]} -gt 0 ]]; then
    echo "To fix PATH duplicates, review your shell config files (.zshenv, .zshrc, etc.)"
fi

if ! grep -q "ZED.*return" ~/.zshrc 2>/dev/null && grep -q "exec zellij" ~/.zshrc 2>/dev/null; then
    echo "Add this to your .zshrc before the zellij exec:"
    echo "  # Skip Zellij auto-start for Zed"
    echo "  [[ -n \"\$ZED\" ]] && return"
fi

echo
echo "✨ Debug complete! Review the output above for any issues."
