# =============================================================================
# mk/test.mk – Testing targets
# =============================================================================

##@ Testing

.PHONY: test
test: ## Ejecuta los tests unitarios y de integración con Bats
	@printf "$(C_CYAN)▶ Ejecutando batería de tests...$(C_RESET)\n"
	@if ! command -v bats > /dev/null; then \
		printf "$(C_RED)✗ Bats no está instalado. Instálalo con 'brew install bats-core' o 'apt install bats'$(C_RESET)\n"; \
		exit 1; \
	fi
	@bats tests/
