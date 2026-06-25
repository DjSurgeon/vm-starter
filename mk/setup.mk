# =============================================================================
# mk/setup.mk – Template and Project setup targets
# =============================================================================

##@ Environment Setup

.PHONY: template project re

template: ## Crea la plantilla base (devpod-base)
	@printf "$(C_CYAN)▶ Creating base template with user: $(C_BOLD)$${USER_NAME:-$(ADMIN_USER)}$(C_RESET)\n"
	@chmod +x template/create-template.sh
	@ADMIN_USER=$${USER_NAME:-$(ADMIN_USER)} ./template/create-template.sh

project: ## Crea un nuevo proyecto (uso: make project NAME=foo TYPE=web)
	@chmod +x scripts/clone.sh 2>/dev/null || true
	@if [ -z "$${NAME:-}" ] || [ -z "$${TYPE:-}" ]; then \
		read -p "Project name: " PROJECT_NAME; \
		read -p "Project type (web/inception): " PROJECT_TYPE; \
		./scripts/clone.sh "$$PROJECT_NAME" "$$PROJECT_TYPE"; \
	else \
		./scripts/clone.sh "$(NAME)" "$(TYPE)"; \
	fi

re: vclean template ## Limpia el entorno y reconstruye la plantilla base
	@printf "$(C_GREEN)✓ Rebuild complete.$(C_RESET)\n"
