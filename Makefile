.PHONY: help install install-zsh install-bash clean validate validate-zsh validate-bash lint

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
MAKEFLAGS += --warn-undefined-variables

DOTFILES_HOME ?= $(shell pwd)
SHELL_CONFIG  := $(DOTFILES_HOME)/config/shell
SCRIPTS_DIR   := $(DOTFILES_HOME)/scripts

help:
	@echo "Dotfiles Management"
	@echo "  make install       - Install shell config (auto-detect)"
	@echo "  make install-zsh   - Install Zsh configuration"
	@echo "  make install-bash  - Install Bash configuration"
	@echo "  make validate      - Syntax-check all shell configs"
	@echo "  make validate-zsh  - Syntax-check Zsh configs"
	@echo "  make validate-bash - Syntax-check Bash configs"
	@echo "  make clean         - Remove broken symlinks in HOME"
	@echo "  make lint          - Run shellcheck on shell modules"

install:
	@bash "$(SCRIPTS_DIR)/install.sh" auto

install-zsh:
	@bash "$(SCRIPTS_DIR)/install.sh" zsh

install-bash:
	@bash "$(SCRIPTS_DIR)/install.sh" bash

clean:
	@find "$(HOME)" -maxdepth 1 -xtype l -delete 2>/dev/null || true
	@echo "Removed broken symlinks in HOME"

validate: validate-zsh validate-bash

validate-zsh:
	@echo "Validating Zsh configuration..."
	@zsh -n "$(SHELL_CONFIG)/zsh/.zshenv"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zprofile"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zshrc"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zlogin"
	@zsh -n "$(SHELL_CONFIG)/zsh/.zlogout"
	@zsh -n "$(SHELL_CONFIG)/.zaliases"
	@zsh -n "$(SHELL_CONFIG)/.zfunctions"
	@echo "Zsh syntax OK"

validate-bash:
	@echo "Validating Bash configuration..."
	@bash -n "$(SHELL_CONFIG)/bash/.bash_env"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_profile"
	@bash -n "$(SHELL_CONFIG)/bash/.bashrc"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_login"
	@bash -n "$(SHELL_CONFIG)/bash/.bash_logout"
	@echo "Bash syntax OK"

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x "$(SHELL_CONFIG)/lib/"*.sh "$(SHELL_CONFIG)/bash/modules/"*.bash; \
	else \
		echo "shellcheck not installed — skipping"; \
	fi