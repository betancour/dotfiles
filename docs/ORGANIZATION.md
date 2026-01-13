# Repository Organization Guide

## Directory Structure

```
dotfiles/
├── config/                 # All configuration files
│   ├── shell/             # Shell configuration
│   │   ├── .zshrc
│   │   ├── .zshenv
│   │   ├── .zprofile
│   │   ├── .zlogin
│   │   ├── .zlogout
│   │   ├── .zaliases
│   │   └── .zfunctions
│   ├── terminal/          # Terminal emulator configurations
│   │   ├── .zshrc.local.template
│   │   ├── IBM-5153.itermcolors
│   │   └── .vimrc
│   └── editor/            # Editor/IDE configurations
│       ├── nvim/          # Neovim configuration
│       ├── alacritty/     # Alacritty terminal
│       ├── waybar/        # Waybar configuration
│       └── zellij/        # Zellij terminal multiplexer
│
├── docs/                   # Documentation
│   ├── DECOUPLING_ANALYSIS.md
│   ├── ZED_COMPATIBILITY_FIXES.md
│   ├── ZSH_CONFIG.md
│   └── SETUP_SUMMARY.md
│
├── storage/               # Data storage
│   ├── backups/          # Backup files
│   └── logs/             # Application logs
│
├── .github/              # GitHub Actions workflows
│   └── workflows/
│
├── Makefile              # Build automation
├── .devopsrc            # Configuration and environment variables
├── README.md            # Main project documentation
├── LICENSE              # License
├── .gitconfig           # Git configuration
└── .gitignore           # Git ignore rules
```

## Key Improvements

### 1. **Separation of Concerns**
- Configuration files organized by type (shell, terminal, editor)
- Each category has its own directory for easier maintenance

### 2. **Scalability**
- Easy to add new configuration categories
- Clear structure for monorepo expansion
- Ready for Infrastructure-as-Code tools

### 3. **Documentation**
- Centralized docs directory
- Clear directory structure documentation
- Makefile for common operations

### 4. **DevOps Best Practices**
- No executable scripts in root directory
- Environment variables defined in `.devopsrc`
- Makefile for consistent operations
- Git configuration separated from application configs

## Usage

### Setting up environment variables
```bash
source .devopsrc
```

### Available Make targets
```bash
make help              # Show all available targets
make install           # Install dotfiles
make validate          # Validate configurations
make clean             # Clean up broken symlinks
```

## Adding New Configurations

1. Create appropriate directory under `config/` based on configuration type
2. Place configuration files there
3. Update documentation
4. Update Makefile if needed for automation

## Best Practices

- Keep configurations in version control (Git)
- Use `.gitignore` for sensitive files
- Document any manual setup steps
- Validate configurations regularly
- Back up critical files in `storage/backups/`
