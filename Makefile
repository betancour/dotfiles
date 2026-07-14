# Makefile — common operations for the dotfiles repository

DOTFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR  := $(DOTFILES_DIR)/scripts
SHELL_CONFIG := $(DOTFILES_DIR)/config/shell
LIB_DIR      := $(SHELL_CONFIG)/lib

.PHONY: help install install-zsh install-bash install-both \
	validate validate-zsh validate-bash lint clean

help:
	@echo "Dotfiles targets:"
	@echo "  install        Install config for current shell (auto-detect)"
	@echo "  install-zsh    Install Zsh configuration"
	@echo "  install-bash   Install Bash configuration"
	@echo "  install-both   Install both shells"
	@echo "  validate       Syntax-check shared lib + both shells"
	@echo "  lint           Run shellcheck on shared lib (if installed)"
	@echo "  clean          Remove broken symlinks in \$$HOME"

install:
	@sh "$(SCRIPTS_DIR)/install.sh" auto

install-zsh:
	@sh "$(SCRIPTS_DIR)/install.sh" zsh

install-bash:
	@sh "$(SCRIPTS_DIR)/install.sh" bash

install-both:
	@sh "$(SCRIPTS_DIR)/install.sh" both

validate: validate-zsh validate-bash
	@echo "Validating shared library..."
	@for f in "$(LIB_DIR)"/*.sh; do \
		bash -n "$$f" || exit 1; \
	done
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

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -s sh "$(SCRIPTS_DIR)/install.sh" "$(DOTFILES_DIR)/install.sh"; \
		shellcheck -x "$(LIB_DIR)"/*.sh || true; \
	else \
		echo "shellcheck not installed — skipping"; \
	fi

clean:
	@find "$(HOME)" -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@echo "Removed broken symlinks in HOME"
