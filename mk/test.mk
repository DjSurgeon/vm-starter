# =============================================================================
# mk/test.mk – Testing targets
# =============================================================================

##@ Testing

.PHONY: test
test: ## Runs unit and integration tests using Bats
	@printf "$(C_CYAN)▶ Running test suite...$(C_RESET)\n"
	@if ! command -v bats > /dev/null; then \
		printf "$(C_RED)✗ Bats is not installed. Install it via 'brew install bats-core' or 'apt install bats'$(C_RESET)\n"; \
		exit 1; \
	fi
	@bats tests/
