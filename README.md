# Dotfiles 🖥️✨

Welcome to my dotfiles repository! This collection of configurations is designed to enhance your command-line experience on both **Linux** and **macOS**. Let's make your terminal as awesome as you are!

## 📋 Table of Contents

- [Shell Configuration (ZSH)](#shell-configuration-zsh)
- [Neovim Setup](#neovim-setup)
- [Alacritty Terminal](#alacritty-terminal)
- [Git Configuration](#git-configuration)
- [Installation](#installation)
- [Dependencies](#dependencies)

## 🐚 Shell Configuration (ZSH)

This setup includes a comprehensive ZSH configuration with:
- Custom prompt with Git integration
- Extensive aliases for modern CLI tools
- Environment variables for optimal shell experience
- Login/logout messages

### Key Features
- **Smart Git Prompt**: Shows branch status with clean/dirty indicators
- **Modern CLI Tools**: Aliases for `eza`, `bat`, `ripgrep`, `fzf`, and more
- **Cross-platform**: Works on both macOS and Linux

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
git clone https://github.com/betancour/dotfiles.git ~/dotfiles
```

2. Create symbolic links:
```bash
# ZSH files
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.zaliases ~/.zaliases
ln -sf ~/dotfiles/.zshenv ~/.zshenv
ln -sf ~/dotfiles/.zprofile ~/.zprofile
ln -sf ~/dotfiles/.zlogin ~/.zlogin
ln -sf ~/dotfiles/.zlogout ~/.zlogout

# Git configuration
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.vimrc ~/.vimrc

# Neovim
ln -sf ~/dotfiles/nvim ~/.config/nvim

# Alacritty
ln -sf ~/dotfiles/alacritty ~/.config/alacritty
```

3. Reload your shell:
```bash
source ~/.zshrc
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

## 🤝 Contributing

Feel free to fork this repository and customize it for your needs. If you find improvements or fixes, pull requests are welcome!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).