# Copilot Instructions for Dotfiles Repository

This dotfiles repository contains configurations for shell, terminal emulators, and editor environments. It follows senior DevOps engineer standards with clear separation of concerns and infrastructure-as-code principles.

## Repository Structure

```
config/
├── shell/          # ZSH shell files (.zshrc, .zshenv, .zprofile, .zlogin, .zlogout, .zaliases, .zfunctions)
├── terminal/       # Terminal emulator configs (.vimrc, .zshrc.local.template, iTerm colors)
└── editor/         # Editor/IDE configurations
    ├── nvim/       # Neovim setup with plugins and LSP
    ├── alacritty/  # Alacritty terminal config (TOML-based, modular)
    ├── tmux/       # Tmux multiplexer configuration
    ├── waybar/     # Linux waybar status bar
    └── zellij/     # Zellij terminal multiplexer

docs/               # Architecture, organization, and setup documentation
storage/            # Backups and logs (not version controlled)
```

## Build, Test & Lint Commands

```bash
# Validate configuration syntax and structure
make validate

# Check for configuration issues
make lint

# Format configuration files
make format

# Clean up broken symlinks
make clean

# Install/link all dotfiles
make install

# Show all available targets
make help
```

These are placeholder implementations in the Makefile that confirm configuration structure. The actual validation happens through manual sourcing and testing shell behavior.

## High-Level Architecture

### 1. ZSH Configuration System (Core)

The ZSH setup uses a **multi-file initialization chain** following standard shell initialization order:

1. **`.zshenv`** — Always loaded first
   - Environment variables, PATH setup, XDG Base Directory spec
   - Platform-specific settings (macOS vs Linux)
   - Tool configurations (FZF, Ripgrep, Docker, etc.)

2. **`.zprofile`** — Login shells only
   - One-time initialization: Homebrew, SSH agents, GPG, language environments
   - Development environment setup (Java, Python, Node, Ruby, Rust, Go)

3. **`.zshrc`** — Interactive shells
   - ZSH options (history, completion, globbing, directory handling)
   - Plugin loading (zsh-autosuggestions, zsh-syntax-highlighting)
   - Custom prompt with Git integration
   - Lazy loading of heavy tools (NVM loads on-demand)
   - Function and alias loading

4. **`.zlogin`** — Post-interactive login setup
   - Welcome messages and system info display
   - Update notifications

5. **`.zlogout`** — Session cleanup
   - Farewell messages and resource cleanup

### 2. Modular Aliases & Functions

- **`.zaliases`** — Smart aliases with fallback support
  - Modern CLI replacements (eza for ls, bat for cat, etc.)
  - All aliases gracefully fall back to standard UNIX tools if modern versions aren't installed
  
- **`.zfunctions`** — 50+ custom utility functions
  - Directory operations (mkcd, up, extract)
  - File utilities (backup, fsize, ff for fuzzy find)
  - Git helpers (gitcp, dps)
  - System info (sysinfo, myip, weather)
  - Text processing (count, replace)

### 3. Terminal & Editor Configurations

- **Alacritty** — TOML-based, modular configuration
  - Separated concerns: alacritty.toml (main), theme.toml, font.toml, btop.toml
  - Font family variations (JetBrainsMono, CaskaydiaMono, BlexMono, FiraMono, MesloLGS)
  
- **Neovim** — LSP-based editor with plugin management
  - Uses Mason for LSP/tool management, Packer for plugins
  - Treesitter for syntax, Telescope for fuzzy finding
  
- **Tmux & Zellij** — Terminal multiplexers with dedicated configs

### 4. Local Customizations

- **`.zshrc.local.template`** — Template for machine-specific settings
  - Copy to `~/.zshrc.local` to customize without modifying repo files
  - Supports local environment variables, API keys, work-specific configs

## Key Conventions

### File Organization Principles

- **By category, not tooling**: `config/shell/`, `config/editor/`, `config/terminal/`
- **Modular over monolithic**: Alacritty uses separate TOML files for themes, fonts, btop config
- **No root-level executable scripts**: All automation via Makefile
- **Environment variables in `.devopsrc`**: Centralized config repository setup
- **Version control friendly**: Uses `.gitignore` for sensitive files, backups in `storage/`

### Shell Configuration Conventions

1. **Sourcing order is critical**: Files load in ZSH initialization sequence. Never assume `.zshrc` has fully sourced all setup
2. **Conditional tool detection**: All aliases/functions check for tool availability first
   ```bash
   # Example pattern: graceful fallback
   alias ls='eza' 2>/dev/null || alias ls='ls --color'
   ```
3. **Lazy loading for performance**: Heavy tools like NVM load only when first invoked
4. **XDG Base Directory compliance**: Respects `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, etc.
5. **Platform-aware code**: Separate logic for macOS (`uname -s` = Darwin) vs Linux

### Documentation Conventions

- **`docs/ZSH_CONFIG.md`** — Comprehensive guide to ZSH file purposes and loading order
- **`docs/ORGANIZATION.md`** — Directory structure and design rationale
- **File headers in config files** — Detailed comments explaining purpose and usage
- **README.md** — Installation, dependencies, and usage tips

### Alacritty Configuration

- **Always use TOML format** (not YAML)
- **Modular split**: 
  - Main config references other files with `import = [...]`
  - Theme, fonts, and special configs in separate files
  - Font sizes and font family choices in dedicated files

### Git Conventions

- **Config provided**: `.gitconfig` included with aliases and optimized settings
- **Git integration in prompt**: Custom prompt shows clean/dirty status with indicators
- **Helper functions**: `gitcp` and others for common workflows

## Common Tasks

### Add a New Alias
1. Edit `config/shell/.zaliases`
2. Use the fallback pattern: `alias myalias='modern-tool' 2>/dev/null || alias myalias='fallback'`
3. Document in `.zaliases` header or `README.md` if public-facing

### Add a Custom Function
1. Edit `config/shell/.zfunctions`
2. Include a brief comment explaining purpose and arguments
3. Test by sourcing: `source config/shell/.zfunctions`

### Customize for Specific Machine
1. Copy `config/terminal/.zshrc.local.template` to `~/.zshrc.local`
2. Add machine-specific settings without modifying repo files
3. This file is automatically sourced at end of `.zshrc`

### Update Terminal Theme
1. Edit `config/editor/alacritty/theme.toml` for current color scheme
2. Add new theme in separate file if needed
3. Reference in main `config/editor/alacritty/alacritty.toml`

### Test Shell Configuration
```bash
# Source and validate without spawning new shell
source ~/.zshenv && source ~/.zprofile && source ~/.zshrc

# Profile startup performance
ZSH_PROFILE_STARTUP=1 zsh
```

## Performance Considerations

- **Lazy loading**: NVM and other heavy tools load on-demand to keep startup fast
- **Completion caching**: ZSH completion system uses caching for faster tab completion
- **Conditional loading**: Tools only initialize if installed (graceful degradation)
- **Optional profiling**: Set `ZSH_PROFILE_STARTUP=1` to identify bottlenecks

## Testing & Validation

- Run `make lint` to check configuration files
- Test ZSH files individually: `bash -n config/shell/.zshrc` (bash parser validates syntax)
- Validate Alacritty TOML: `alacritty --print-config-location` shows if config has errors
- Check symlinks: `make clean` removes broken symlinks
