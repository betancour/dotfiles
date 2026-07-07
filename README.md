# Dotfiles 🖥️✨

Welcome to my dotfiles repository! This collection of configurations is designed to enhance your command-line experience on both **Linux** and **macOS**. Let's make your terminal as awesome as you are!

## Branch Strategy

| Branch | Primary shell | Install command |
|--------|---------------|-----------------|
| `main` | Zsh | `make install-zsh` or `./scripts/install.sh zsh` |
| `bash` | Bash | `make install-bash` or `./scripts/install.sh bash` |

Both branches share the same modular architecture under `config/shell/` and provide feature-equivalent aliases, functions, prompts, and login behavior. Shell-specific differences are isolated to `config/shell/zsh/` and `config/shell/bash/`; shared logic lives in `config/shell/lib/`.

## 📋 Table of Contents

- [Shell Configuration (ZSH)](#shell-configuration-zsh)
- [ZSH Configuration Files](#zsh-configuration-files)
- [Neovim Setup](#neovim-setup)
- [Alacritty Terminal](#alacritty-terminal)
- [Git Configuration](#git-configuration)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Customization](#customization)
- [Performance Features](#performance-features)

## 🐚 Shell Configuration (ZSH)

This setup includes a comprehensive, professional-grade ZSH configuration with:

- **Complete initialization chain**: Proper `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout` setup
- **Custom prompt with Git integration**: Real-time Git status with clean/dirty indicators
- **Extensive aliases with fallbacks**: Modern CLI tools with graceful degradation
- **50+ custom functions**: Enhanced productivity with built-in utilities
- **Performance optimizations**: Fast startup, lazy loading, efficient completion
- **Cross-platform support**: Works seamlessly on macOS and Linux
- **XDG Base Directory compliance**: Clean, organized configuration
- **Security features**: Proper agent management and cleanup

### ZSH Configuration Files

This dotfiles repository includes a complete set of ZSH initialization files following best practices:

#### Core Files
- **`.zshenv`** - Environment variables and PATH (always loaded)
- **`.zprofile`** - Login shell initialization and tool setup
- **`.zshrc`** - Interactive shell configuration and user experience
- **`.zlogin`** - Post-interactive setup and welcome messages
- **`.zlogout`** - Session cleanup and farewell
- **`.zaliases`** - Smart aliases with fallbacks for missing tools
- **`.zfunctions`** - 50+ custom utility functions

#### Key Features
- **Smart Tool Detection**: Aliases work even without modern CLI tools installed
- **Lazy Loading**: Heavy tools like NVM load on-demand for faster startup
- **Session Management**: Comprehensive login/logout with system information
- **Development Integration**: Git, Docker, Node.js, Python, Ruby, Rust, Go support
- **Performance Monitoring**: Optional startup profiling and optimization
- **Local Customization**: Template for machine-specific settings

## 🎨 Neovim Setup

Modern Neovim configuration with:
- Plugin management with Packer
- LSP support with Mason
- Treesitter for syntax highlighting
- Telescope for fuzzy finding
- Rose Pine color scheme

## 🖥️ Alacritty Terminal

Customized Alacritty configuration with:
- Modular configuration files
- Custom themes and fonts
- Optimized for development workflow

## 🔧 Git Configuration

Comprehensive Git setup with:
- Custom aliases and colors
- Git LFS support
- Optimized diff and merge tools

## 📦 Installation

### Prerequisites

Install required tools for the best experience:

**macOS (using Homebrew):**
```bash
brew install eza bat ripgrep fzf fd zoxide neovim git-lfs
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install bat ripgrep fzf fd-find zoxide neovim git-lfs
# Note: On Ubuntu, 'bat' might be installed as 'batcat'
```

### ZSH Plugins Setup

1. Install Oh My Zsh (optional but recommended):
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. Install ZSH plugins:
```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting  
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

3. The plugins are already configured in `.zshrc`:
```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

### Dotfiles Installation

1. Clone this repository:
```bash
git clone https://github.com/betancour/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
```

2. Install shell configuration:
```bash
# Zsh (main branch)
make install-zsh

# Bash (bash branch)
git checkout bash && make install-bash

# Or install both from either branch
./scripts/install.sh both
```

3. Reload your shell:
```bash
exec $SHELL -l
```

## 🛠️ Dependencies

### Core Tools
- **zsh**: The Z shell
- **git**: Version control
- **neovim**: Modern Vim-based editor

### Enhanced CLI Tools
- **eza**: Modern replacement for `ls`
- **bat**: Cat with syntax highlighting
- **ripgrep**: Fast text search
- **fzf**: Fuzzy finder
- **fd**: Fast alternative to `find`
- **zoxide**: Smart directory jumping

### Optional Tools
- **lazygit**: Terminal UI for Git
- **lazydocker**: Terminal UI for Docker
- **zellij**: Terminal multiplexer

## 🎯 Usage Tips

### Directory Navigation
- Use `z <dirname>` to jump to frequently used directories
- Use `..`, `...`, `....` for quick parent directory navigation
- Use `lt` for tree view with Git status

### File Operations
- Use `ls`, `ll`, `la` for enhanced file listing
- Use `cat` for syntax-highlighted file viewing
- Use `ff` for fuzzy file finding with preview

### Git Workflow
- Use `g` as shorthand for `git`
- Use `gcm "message"` for quick commits
- Use `lzg` for LazyGit interface

### Editor
- Use `n` to open Neovim in current directory or with files
- Use `vi` (aliased to `nvim`) for quick edits

## 🎨 Customization

### Machine-Specific Settings
Create local customizations without modifying the main dotfiles:

```bash
# Copy the template and customize
cp .zshrc.local.template ~/.zshrc.local
# Edit for your specific needs
```

### Available Customizations
- Local environment variables and API keys
- Machine-specific aliases and functions
- Work-specific configurations
- Custom prompt modifications
- Local tool initialization

### Custom Functions
Type `help` in your shell to see all available custom functions:
- Directory operations (`mkcd`, `up`, `extract`)
- File utilities (`backup`, `fsize`)
- System information (`sysinfo`, `myip`)
- Development tools (`gitcp`, `dps`)
- Text processing (`count`, `replace`)
- Utilities (`weather`, `genpass`)

## 🚀 Performance Features

### Startup Optimization
- Conditional loading prevents errors on missing tools
- Lazy loading for heavy tools (NVM loads on-demand)
- Efficient completion system with caching
- Background task management

### Monitoring
Enable startup profiling:
```bash
ZSH_PROFILE_STARTUP=1 zsh
```

### Session Management
- Automatic history backups
- Session duration tracking
- Performance monitoring
- Resource cleanup on exit

## 📚 Documentation

- **[ZSH_CONFIG.md](ZSH_CONFIG.md)** - Comprehensive ZSH configuration guide
- **[.zshrc.local.template](.zshrc.local.template)** - Local customization examples
- Individual file headers contain detailed documentation

## 🔧 Troubleshooting

### Common Issues
- **Slow startup**: Use `ZSH_PROFILE_STARTUP=1` to identify bottlenecks
- **Missing tools**: All aliases have fallbacks to standard UNIX tools
- **Path issues**: Check `.zshenv` for PATH configuration

### Reset Configuration
```bash
# Backup and reset if needed
mv ~/.zshrc ~/.zshrc.backup
./install.sh
```

## 📜 Scripts

The `scripts/` directory contains utility scripts for system management:

### Zellij Session Management
- **`cleanup-zellij.sh`** - Interactive script for managing Zellij sessions

#### Installation
Make scripts executable and accessible:
```bash
# Make script executable
chmod +x ~/dotfiles/scripts/cleanup-zellij.sh

# Optional: Add scripts directory to PATH in .zshrc.local
echo 'export PATH="$HOME/dotfiles/scripts:$PATH"' >> ~/.zshrc.local
```

#### Usage
```bash
# Clean up exited sessions (recommended alias: zclean)
~/dotfiles/scripts/cleanup-zellij.sh --clean

# List all sessions
~/dotfiles/scripts/cleanup-zellij.sh --list

# Interactive cleanup mode
~/dotfiles/scripts/cleanup-zellij.sh --interactive

# Clean sessions older than N days
~/dotfiles/scripts/cleanup-zellij.sh --old 7 --clean

# See all options
~/dotfiles/scripts/cleanup-zellij.sh --help
```

## 🤝 Contributing

Feel free to fork this repository and customize it for your needs. If you find improvements or fixes, pull requests are welcome!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).