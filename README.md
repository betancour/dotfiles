# Dotfiles 🖥️✨

Welcome to my comprehensive dotfiles repository! This collection of configurations is designed to enhance your command-line experience on both **Linux** and **macOS** with professional-grade **Bash** and **ZSH** configurations.

## 📋 Table of Contents

- [Shell Configurations](#shell-configurations)
  - [Bash Configuration](#bash-configuration-recommended)
  - [ZSH Configuration](#zsh-configuration)
- [Installation](#installation)
- [Configuration Files](#configuration-files)
- [Dependencies](#dependencies)
- [Customization](#customization)
- [Performance Features](#performance-features)
- [Documentation](#documentation)

## 🐚 Shell Configurations

This repository provides two complete, professional shell configurations:

### Bash Configuration (Recommended)
A comprehensive, modern Bash setup with enterprise-grade features:

- **Complete initialization chain**: `.bash_env`, `.bash_profile`, `.bashrc`, `.bash_logout`
- **Smart prompt with Git integration**: Real-time branch status and command timing
- **Extensive aliases with fallbacks**: Modern CLI tools with graceful degradation
- **50+ custom functions**: Enhanced productivity utilities (`help` command to see all)
- **Performance optimizations**: Fast startup, lazy loading, efficient completion
- **Cross-platform support**: Works seamlessly on macOS and Linux
- **XDG Base Directory compliance**: Clean, organized configuration
- **Security features**: Proper agent management and cleanup

#### Key Features
- **Smart Tool Detection**: All aliases work even without modern CLI tools installed
- **Session Management**: Comprehensive login/logout with system information and cleanup
- **Development Integration**: Git, Docker, Kubernetes, Node.js, Python, Ruby, Rust, Go support
- **Performance Monitoring**: Optional startup profiling and command timing
- **Local Customization**: Template for machine-specific settings

### ZSH Configuration
A feature-rich ZSH setup with advanced shell capabilities:

- **Complete ZSH initialization files**: `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout`
- **Oh My Zsh integration** with fallback support
- **Advanced prompt** with VCS integration
- **Plugin support**: autosuggestions, syntax highlighting
- **Enhanced completion system**
- **50+ utility functions**

## 📦 Installation

### Quick Start (Bash - Recommended)
```bash
# Clone the repository
git clone https://github.com/betancour/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install Bash configuration
./install_bash.sh
```

### Quick Start (ZSH)
```bash
# Clone the repository
git clone https://github.com/betancour/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install ZSH configuration (fix ZSH issues first if needed)
./install.sh
```

### Prerequisites

Install modern CLI tools for the best experience:

**macOS (using Homebrew):**
```bash
brew install eza bat ripgrep fzf fd zoxide neovim git-lfs bash-completion
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install bat ripgrep fzf fd-find zoxide neovim git-lfs bash-completion
# Note: On Ubuntu, 'bat' might be installed as 'batcat'
```

## 📁 Configuration Files

### Bash Files
- **`.bash_env`** - Environment variables and PATH (sourced by all)
- **`.bash_profile`** - Login shell initialization and tool setup
- **`.bashrc`** - Interactive shell configuration and user experience
- **`.bash_logout`** - Session cleanup and farewell
- **`.bash_aliases`** - Smart aliases with fallbacks for missing tools
- **`.bash_functions`** - 50+ custom utility functions

### ZSH Files
- **`.zshenv`** - Environment variables and PATH (always loaded)
- **`.zprofile`** - Login shell initialization
- **`.zshrc`** - Interactive shell configuration
- **`.zlogin`** - Post-interactive setup and welcome messages
- **`.zlogout`** - Session cleanup and farewell
- **`.zaliases`** - Smart aliases with fallbacks
- **`.zfunctions`** - 50+ custom utility functions

### Shared Files
- **`.gitconfig`** - Git configuration with aliases and colors
- **`.gitignore`** - Global gitignore patterns
- **`.vimrc`** - Vim configuration

## 🛠️ Dependencies

### Core Tools
- **bash** or **zsh**: The shell
- **git**: Version control
- **curl**: For web requests and installations

### Enhanced CLI Tools (Optional but Recommended)
- **eza**: Modern replacement for `ls`
- **bat**: Cat with syntax highlighting
- **ripgrep (rg)**: Fast text search
- **fzf**: Fuzzy finder
- **fd**: Fast alternative to `find`
- **zoxide**: Smart directory jumping
- **neovim**: Modern Vim-based editor

### Development Tools (Optional)
- **lazygit**: Terminal UI for Git
- **lazydocker**: Terminal UI for Docker
- **docker**: Container management
- **kubectl**: Kubernetes management

## 🎨 Customization

### Machine-Specific Settings
Create local customizations without modifying the main dotfiles:

**For Bash:**
```bash
# Copy the template and customize
cp .bashrc.local.template ~/.bashrc.local
# Edit for your specific needs
```

**For ZSH:**
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
- **Directory operations**: `mkcd`, `up`, `extract`
- **File utilities**: `backup`, `fsize`, `findfile`
- **System information**: `sysinfo`, `myip`, `localip`
- **Development tools**: `gitcp`, `dps`, `mkproject`
- **Text processing**: `count`, `replace`
- **Utilities**: `weather`, `genpass`, `urlencode/decode`

## 🚀 Performance Features

### Startup Optimization
- Conditional loading prevents errors on missing tools
- Lazy loading for heavy tools (NVM loads on-demand)
- Efficient completion system with caching
- Background task management

### Monitoring
Enable startup profiling:

**Bash:**
```bash
BASH_PROFILE_STARTUP=1 bash -l
```

**ZSH:**
```bash
ZSH_PROFILE_STARTUP=1 zsh -l
```

### Session Management
- Automatic history backups
- Session duration tracking
- Performance monitoring
- Resource cleanup on exit

## 📚 Documentation

- **[BASH_CONFIG.md](BASH_CONFIG.md)** - Comprehensive Bash configuration guide
- **[ZSH_CONFIG.md](ZSH_CONFIG.md)** - Comprehensive ZSH configuration guide
- **Local templates** - Examples for machine-specific customizations
- Individual file headers contain detailed documentation

## 🔧 Usage Tips

### Directory Navigation
- Use `z <dirname>` to jump to frequently used directories (if zoxide installed)
- Use `..`, `...`, `....` for quick parent directory navigation
- Use `lt` for tree view with Git status

### File Operations
- Use `ls`, `ll`, `la` for enhanced file listing
- Use `cat` for syntax-highlighted file viewing (if bat installed)
- Use `fzf_preview` for fuzzy file finding with preview

### Git Workflow
- Use `g` as shorthand for `git`
- Use `gcm "message"` for quick commits
- Use `lzg` for LazyGit interface (if installed)

### Development
- Use `mkproject <name>` to create new projects with git initialization
- Use `dps` to see Docker container status
- Use `k` for kubectl shortcuts

## 🔧 Troubleshooting

### Common Issues
- **Slow startup**: Use profiling to identify bottlenecks
- **Missing tools**: All aliases have fallbacks to standard UNIX tools
- **Path issues**: Check `.bash_env` or `.zshenv` for PATH configuration

### Reset Configuration
```bash
# Backup and reset if needed
mv ~/.bashrc ~/.bashrc.backup
mv ~/.bash_profile ~/.bash_profile.backup
# Or for ZSH
mv ~/.zshrc ~/.zshrc.backup
./install_bash.sh  # or ./install.sh for ZSH
```

### Shell-Specific Issues
- **Bash**: Check syntax with `bash -n <file>`
- **ZSH**: Check syntax with `zsh -n <file>`
- **Function conflicts**: See function help with `help` command

## 🤝 Contributing

Feel free to fork this repository and customize it for your needs. If you find improvements or fixes, pull requests are welcome!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🌟 Features Comparison

| Feature | Bash Config | ZSH Config |
|---------|-------------|------------|
| **Startup Files** | 4 main files | 5 main files |
| **Plugin System** | Manual/bash-completion | Oh My Zsh integration |
| **Prompt** | Git integration + timing | Advanced VCS integration |
| **Completion** | bash-completion system | Advanced built-in system |
| **Performance** | Fast, optimized | Fast with more features |
| **Compatibility** | Universal | Modern systems |
| **Learning Curve** | Gentle | Moderate |

## 🎯 Recommendations

- **New users**: Start with **Bash configuration** - it's more universally compatible
- **Power users**: Try **ZSH configuration** for advanced features
- **Servers**: Use **Bash configuration** for better compatibility
- **Development**: Either works great, choose based on preference

Both configurations provide enterprise-grade functionality with excellent performance and cross-platform compatibility!