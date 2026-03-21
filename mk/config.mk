# =============================================================================
# mk/config.mk – Shared variables and configuration
# =============================================================================

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# Extract variables from the modular configuration using shell calls
VAR_LOADER := source config/config.sh >/dev/null 2>&1 && echo

TEMPLATE_NAME   := $(shell $(VAR_LOADER) $$TEMPLATE_NAME)
ISO_DIR         := $(shell $(VAR_LOADER) $$ISO_DIR)
DISK_IMAGES_DIR := $(shell $(VAR_LOADER) $$DISK_IMAGES_DIR)
DEVPOD_ROOT     := $(shell $(VAR_LOADER) $$DEVPOD_ROOT)
ADMIN_USER      := $(shell $(VAR_LOADER) $$ADMIN_USER)
SSH_PORT        := $(shell $(VAR_LOADER) $$SSH_PORT)

# Inherit colors from config/11-logging.sh (portable codes for Make/Bash)
C_RESET   := \033[0m
C_BOLD    := \033[1m
C_RED     := \033[1;31m
C_GREEN   := \033[1;32m
C_YELLOW  := \033[1;33m
C_BLUE    := \033[1;34m
C_MAGENTA := \033[1;35m
C_CYAN    := \033[1;36m
