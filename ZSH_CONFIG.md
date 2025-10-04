# ZSH Configuration Documentation

This document provides a comprehensive overview of the ZSH configuration files and their purposes in this dotfiles repository.

## 📁 File Structure

```
dotfiles/
├── .zshenv              # Environment variables (always loaded)
├── .zprofile            # Login shell initialization
├── .zshrc               # Interactive shell configuration
├── .zlogin              # Post-interactive login setup
├── .zlogout             # Shell exit cleanup
├── .zaliases            # Shell aliases
├── .zfunctions          # Custom functions
└── .zshrc.local.template # Template for local customizations
```

## 🔄 Loading Order

ZSH loads configuration files in a specific order:

1. **`.zshenv`** - Always sourced (login/non-login, interactive/non-interactive)
2. **`.zprofile`** - Sourced for login shells only
3. **`.zshrc`** - Sourced for interactive shells
4. **`.zlogin`** - Sourced for login shells after `.zshrc`
5. **`.zlogout`** - Sourced when login shells exit

## 📝 File Purposes

### .zshenv - Environment Variables
**When:** Always loaded first
**Purpose:** System-wide environment variables and PATH configuration

**Key Features:**
- Locale settings (UTF-8)
- XDG Base Directory specification
- PATH management with duplicate prevention
- Tool-specific environment variables
- Platform-specific configurations (macOS/Linux)
- Performance optimizations

**Contains:**
- `LANG`, `LC_ALL` settings
- `XDG_*` directory variables
- `PATH` configuration with Homebrew support
- Editor and pager settings
- History configuration
- Tool configurations (FZF, Ripgrep, Docker, etc.)

### .zprofile - Login Shell Setup
**When:** Login shells only, after `.zshenv`
**Purpose:** One-time login initialization

**Key Features:**
- Homebrew environment setup
- SSH agent initialization
- GPG agent setup
- Development environment initialization (Java, Python, Node.js, Ruby, Rust, Go)
- System service setup
- Performance monitoring

**Platform-specific:**
- macOS: Launchd environment, Terminal integration
- Linux: Systemd user environment, D-Bus setup

### .zshrc - Interactive Shell Configuration
**When:** Interactive shells, after `.zprofile`
**Purpose:** Main shell configuration and user experience

**Key Features:**
- ZSH options and settings
- Oh My Zsh integration with fallbacks
- Plugin loading (autosuggestions, syntax highlighting)
- Custom prompt with Git integration
- Key bindings and shortcuts
- Tool initialization (FZF, zoxide, NVM lazy loading)
- Completion system setup

**Plugins Supported:**
- zsh-autosuggestions
- zsh-syntax-highlighting
- Git integration
- Docker completion
- Kubectl completion

### .zlogin - Post-Interactive Setup
**When:** Login shells, after `.zshrc`
**Purpose:** Welcome messages and final setup

**Key Features:**
- System information display
- Development environment status
- Update notifications
- SSH agent integration
- Performance monitoring
- Helpful tips and reminders

**Information Displayed:**
- System specs (hostname, IP, uptime, memory, disk)
- Git status in current directory
- Development tool versions
- Docker container status
- Random productivity tips

### .zlogout - Exit Cleanup
**When:** Login shells exit
**Purpose:** Session cleanup and farewell

**Key Features:**
- Session statistics and duration
- History backup
- Temporary file cleanup
- SSH/GPG agent management
- Background process cleanup
- Development environment cleanup
- Farewell messages

### .zaliases - Shell Aliases
**Purpose:** Command shortcuts and modern tool integration

**Categories:**
- Directory navigation (with zoxide fallbacks)
- File operations (eza, bat, ripgrep with fallbacks)
- Development tools (git, docker, lazygit)
- System utilities
- Network tools

**Smart Fallbacks:**
- Works even if modern CLI tools aren't installed
- Graceful degradation to standard UNIX tools

### .zfunctions - Custom Functions
**Purpose:** Extended shell functionality

**Function Categories:**
- **Directory Operations:** `mkcd`, `up`, `cdf`, `extract`
- **File Operations:** `ff`, `fd`, `fsize`, `backup`
- **System Information:** `sysinfo`, `dusk`, `pstree`
- **Network Operations:** `myip`, `localip`, `pingtest`
- **Development Utilities:** `gitclean`, `gitcp`, `gitbr`, `dps`, `dclean`
- **Text Processing:** `count`, `replace`
- **Utilities:** `weather`, `genpass`, `urlencode/decode`
- **Performance:** `topcpu`, `topmem`, `timeit`

## 🎨 Customization

### Local Customizations
Create `~/.zshrc.local` for machine-specific settings:
```bash
cp ~/.zshrc.local.template ~/.zshrc.local
```

### Environment Variables
Set in `.zshenv` for system-wide access or `.zshrc.local` for local overrides.

### Aliases and Functions
Add to `.zaliases` for global aliases or `.zshrc.local` for local ones.

### Prompt Customization
Modify prompt variables in `.zshrc` or override in `.zshrc.local`.

## 🚀 Performance Features

### Startup Optimization
- Conditional loading of tools and plugins
- Lazy loading for heavy tools (NVM)
- Efficient completion system
- Background task management

### Memory Management
- Proper history configuration
- Cache directory management
- Temporary file cleanup

### Monitoring
- Optional startup profiling with `ZSH_PROFILE_STARTUP`
- Session logging and statistics
- Performance tracking

## 🔧 Tool Integration

### Modern CLI Tools
- **eza** - Enhanced `ls` replacement
- **bat** - Syntax-highlighted `cat`
- **ripgrep** - Fast text search
- **fzf** - Fuzzy finder
- **fd** - Fast `find` replacement
- **zoxide** - Smart directory jumping

### Development Tools
- **Git** - Enhanced Git integration with status
- **Docker** - Container management aliases
- **Node.js** - NVM lazy loading
- **Python** - Virtual environment support
- **Ruby** - rbenv integration
- **Rust** - Cargo environment
- **Go** - Go environment setup

## 🔒 Security Features

### Environment Isolation
- XDG directory compliance
- Proper file permissions (umask)
- Sensitive variable cleanup on exit

### SSH/GPG Integration
- Secure agent management
- Key loading and cleanup
- Session-specific security

## 📊 Monitoring and Logging

### Session Tracking
- Login/logout timestamps
- Command execution counts
- Session duration tracking

### Performance Monitoring
- Startup time profiling
- Resource usage tracking
- Background task management

## 🌍 Cross-Platform Support

### macOS Features
- Homebrew integration
- Terminal.app and iTerm2 support
- macOS-specific tools and paths
- Launchd environment management

### Linux Features
- Package manager integration
- Systemd user services
- Linux-specific utilities
- Distribution detection

## 🔄 Maintenance

### Automatic Cleanup
- Old history backups (keep last 5)
- Temporary file removal
- Completion cache management
- Session file rotation

### Update Management
- Homebrew update notifications
- Package update checking
- Plugin update handling

## 🆘 Troubleshooting

### Common Issues
1. **Slow startup:** Check `ZSH_PROFILE_STARTUP=1` for timing
2. **Missing tools:** Aliases have fallbacks to standard tools
3. **Path issues:** Check `.zshenv` PATH configuration
4. **Plugin problems:** Fallbacks work without Oh My Zsh

### Debugging
- Use `zsh -xvs` for verbose startup
- Check logs in `${XDG_STATE_HOME}/zsh/`
- Review startup timing with profiling

### Reset Configuration
```bash
mv ~/.zshrc ~/.zshrc.backup
source ~/.zshenv
```

## 📚 Additional Resources

### ZSH Documentation
- [ZSH Manual](http://zsh.sourceforge.net/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)

### Tool Documentation
- Individual tool documentation linked in aliases
- Function help via `help` command
- Man pages for system integration

## 🎯 Best Practices

1. **Keep `.zshenv` fast** - Only essential environment variables
2. **Use `.zshrc.local`** - For machine-specific customizations
3. **Leverage fallbacks** - Ensure compatibility across systems
4. **Monitor performance** - Use profiling for optimization
5. **Regular cleanup** - Let automatic maintenance work
6. **Security first** - Keep sensitive data in local files only

This configuration provides a robust, performant, and user-friendly ZSH environment that works across different systems and use cases while maintaining excellent performance and security practices.