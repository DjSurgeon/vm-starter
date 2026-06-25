# =============================================================================
# mk/setup.mk – Template and Project setup targets
# =============================================================================

##@ Environment Setup

.PHONY: template project re

template: ## Creates the base template (devpod-base)
	@printf "%b▶ Creating base template with user: %b%s%b\n" "$(C_CYAN)" "$(C_BOLD)" "$${USER_NAME:-$(ADMIN_USER)}" "$(C_RESET)"
	@chmod +x template/create-template.sh
	@ADMIN_USER=$${USER_NAME:-$(ADMIN_USER)} ./template/create-template.sh

project: ## Creates a new project (usage: make project NAME=foo TYPE=web)
	@chmod +x scripts/clone.sh 2>/dev/null || true
	@if [ -z "$${NAME:-}" ] || [ -z "$${TYPE:-}" ]; then \
		read -p "Project name: " PROJECT_NAME; \
		read -p "Project type (web/inception): " PROJECT_TYPE; \
		./scripts/clone.sh "$$PROJECT_NAME" "$$PROJECT_TYPE"; \
	else \
		./scripts/clone.sh "$(NAME)" "$(TYPE)"; \
	fi

re: vclean template ## Cleans the environment and rebuilds the base template
	@printf "%b✓ Rebuild complete.%b\n" "$(C_GREEN)" "$(C_RESET)"
