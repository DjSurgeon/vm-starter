# =============================================================================
# mk/config.mk – Shared variables and configuration
# =============================================================================

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# Extract variables from the modular configuration using shell calls
VAR_LOADER := source config/config.sh >/dev/null 2>&1 && echo
TEMPLATE_NAME := $(shell $(VAR_LOADER) $$TEMPLATE_NAME)
ISO_DIR := $(shell $(VAR_LOADER) $$ISO_DIR)
DISK_IMAGES_DIR := $(shell $(VAR_LOADER) $$DISK_IMAGES_DIR)
ADMIN_USER := $(shell $(VAR_LOADER) $$ADMIN_USER)
SSH_PORT := $(shell $(VAR_LOADER) $$SSH_PORT)

# Colours (portable via printf)
C_RESET   := \033[0m
C_BOLD    := \033[1m
C_GREEN   := \033[32m
C_YELLOW  := \033[33m
C_CYAN    := \033[36m
C_BLUE    := \033[34m
C_RED     := \033[31m
C_MAGENTA := \033[35m
