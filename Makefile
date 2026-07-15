# Makefile — common operations for the dotfiles repository

DOTFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR  := $(DOTFILES_DIR)/scripts
LIB_DIR      := $(DOTFILES_DIR)/lib
SHELL_CONFIG := $(DOTFILES_DIR)/config/shell
SH_LIB       := $(SHELL_CONFIG)/lib

.PHONY: help install install-zsh install-bash install-sh install-both install-all \
	install-deps dry-run uninstall \
	validate validate-zsh validate-bash validate-sh lint clean

help:
	@echo "Dotfiles targets:"
	@echo "  install         Install config for current shell (auto-detect)"
	@echo "  install-zsh     Install Zsh configuration"
	@echo "  install-bash    Install Bash configuration"
	@echo "  install-sh      Install POSIX sh configuration"
	@echo "  install-both    Install Bash + Zsh"
	@echo "  install-all     Install Bash + Zsh + sh"
	@echo "  install-deps    Install packages only"
	@echo "  dry-run         Show what install would do"
	@echo "  uninstall       Remove managed symlinks / blocks"
	@echo "  validate        Syntax-check shared lib + all shells"
	@echo "  lint            Run shellcheck on installer + libs"
	@echo "  clean           Remove broken symlinks in \$$HOME"

install:
	@sh "$(DOTFILES_DIR)/install.sh" auto

install-zsh:
	@sh "$(DOTFILES_DIR)/install.sh" zsh

install-bash:
	@sh "$(DOTFILES_DIR)/install.sh" bash

install-sh:
	@sh "$(DOTFILES_DIR)/install.sh" sh

install-both:
	@sh "$(DOTFILES_DIR)/install.sh" both

install-all:
	@sh "$(DOTFILES_DIR)/install.sh" all

install-deps:
	@sh "$(DOTFILES_DIR)/install.sh" --only-deps

dry-run:
	@sh "$(DOTFILES_DIR)/install.sh" --dry-run --yes auto

uninstall:
	@sh "$(DOTFILES_DIR)/uninstall.sh"

validate: validate-zsh validate-bash validate-sh
	@echo "Validating shared library..."
	@for f in "$(SH_LIB)"/*.sh; do \
		bash -n "$$f" || exit 1; \
	done
	@echo "Validating installer libraries..."
	@for f in "$(LIB_DIR)"/*.sh "$(DOTFILES_DIR)/bootstrap"/*.sh; do \
		bash -n "$$f" || exit 1; \
	done
	@bash -n "$(DOTFILES_DIR)/install.sh"
	@bash -n "$(DOTFILES_DIR)/uninstall.sh"
	@echo "All syntax checks passed."

validate-zsh:
	@echo "Validating Zsh configuration..."
	@zsh -n "$(SHELL_CONFIG)/zsh/.zshenv"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zprofile"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zshrc"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zlogin"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zlogout"
	@for f in "$(SHELL_CONFIG)/zsh/modules"/*.zsh; do zsh -n "$$f" || exit 1; done
	@echo "Zsh syntax OK"

validate-bash:
	@echo "Validating Bash configuration..."
	@bash -n "$(SHELL_CONFIG)/bash/.bash_env"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_profile"
	@bash -n "$(SHELL_CONFIG)/bash/.bashrc"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_login"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_logout"
	@for f in "$(SHELL_CONFIG)/bash/modules"/*.bash; do bash -n "$$f" || exit 1; done
	@echo "Bash syntax OK"

validate-sh:
	@echo "Validating POSIX sh configuration..."
	@bash -n "$(SHELL_CONFIG)/sh/.profile"
	@bash -n "$(SHELL_CONFIG)/sh/modules/tools.sh"
	@echo "POSIX sh syntax OK"

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -s sh \
			"$(DOTFILES_DIR)/install.sh" \
			"$(DOTFILES_DIR)/uninstall.sh" \
			"$(SCRIPTS_DIR)/install.sh" \
			"$(LIB_DIR)"/*.sh \
			"$(DOTFILES_DIR)/bootstrap"/*.sh \
			"$(SHELL_CONFIG)/sh/.profile" \
			"$(SHELL_CONFIG)/sh/modules/tools.sh"; \
		echo "Installer ShellCheck OK"; \
		shellcheck -s bash -e SC2148,SC1091,SC2296,SC2298,SC2139,SC2262,SC2263 \
			"$(SH_LIB)"/*.sh || true; \
	else \
		echo "shellcheck not installed — skipping (make install-deps or brew install shellcheck)"; \
	fi

clean:
	@find "$(HOME)" -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@echo "Removed broken symlinks in HOME"
