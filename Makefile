# =============================================================================
# VM-Starter Makefile – Modular Entry Point
# =============================================================================

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
help: ## Muestra este menú de ayuda
	@printf "$(C_BOLD)VM-Starter – Development VM Manager$(C_RESET)\n\n"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(C_CYAN)<target>$(C_RESET)\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(C_CYAN)%-15s$(C_RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(C_BOLD)%s$(C_RESET)\n", substr($$0, 5) } \
		' $(MAKEFILE_LIST)
	@echo ""

##@ Interactive Setup

.PHONY: init
init: ## Configura la ruta de almacenamiento (Opcional, útil para 42 Campus)
	@chmod +x scripts/init-env.sh
	@./scripts/init-env.sh

.PHONY: create
create: ## Lanza el asistente interactivo para clonar un nuevo proyecto
	@chmod +x scripts/wizard.sh
	@./scripts/wizard.sh
