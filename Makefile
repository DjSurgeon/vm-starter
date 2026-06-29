# =============================================================================
# VM-Starter Makefile – Modular Entry Point
# =============================================================================

export PATH := $(shell pwd)/.bin:$(PATH)

# 1. Include modular components
include mk/config.mk
include mk/vm-ops.mk
include mk/setup.mk
include mk/system.mk
include mk/test.mk

# 2. Default target
.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Shows this help menu
	@printf "%b" "$(C_CYAN)"
	@cat mk/banner.txt 2>/dev/null || true
	@printf "%b\n\n" "$(C_RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(C_CYAN)<target>$(C_RESET)\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(C_CYAN)%-15s$(C_RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(C_BOLD)%s$(C_RESET)\n", substr($$0, 5) } \
		' $(MAKEFILE_LIST)
	@echo ""

##@ Interactive Setup

.PHONY: init
init: ## Configures the storage path (Optional, useful for 42 Campus)
	@chmod +x scripts/init-env.sh
	@./scripts/init-env.sh

.PHONY: create
create: ## Launches the interactive wizard to clone a new project
	@chmod +x scripts/wizard.sh
	@./scripts/wizard.sh
