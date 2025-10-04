#!/usr/bin/env zsh

# Test script to verify SSH tools are using Homebrew versions
# Run this script to check if the aliases are working correctly

echo "=== Testing SSH Tools - Homebrew vs System ==="
echo

# Source the aliases file
if [[ -f "$HOME/.zaliases" ]]; then
    source "$HOME/.zaliases"
    echo "✓ Loaded aliases from ~/.zaliases"
else
    echo "✗ Could not find ~/.zaliases file"
    exit 1
fi

echo

# Test each SSH tool
tools=("ssh" "ssh-keygen" "ssh-copy-id" "ssh-add" "ssh-agent" "scp" "sftp")

for tool in "${tools[@]}"; do
    echo "Testing $tool:"

    # Check if alias exists
    if alias "$tool" >/dev/null 2>&1; then
        aliased_path=$(alias "$tool" | cut -d"'" -f2)
        echo "  Alias: $aliased_path"

        if [[ -x "$aliased_path" ]]; then
            echo "  Status: ✓ Homebrew version found and executable"
        else
            echo "  Status: ✗ Homebrew version not found or not executable"
        fi
    else
        system_path=$(which "$tool" 2>/dev/null)
        echo "  System: $system_path"
        echo "  Status: ⚠ No alias - using system version"
    fi
    echo
done

echo "=== Summary ==="
echo "When you open a new terminal and run 'ssh-keygen', it should use:"
echo "/opt/homebrew/bin/ssh-keygen"
echo
echo "To verify in a new terminal:"
echo "  ssh-keygen --help 2>&1 | head -1"
echo "  # This should show the newer OpenSSH version"
echo
echo "To see which version you're actually using:"
echo "  type ssh-keygen"
echo "  # This will show if it's aliased or not"
