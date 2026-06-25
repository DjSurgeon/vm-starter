# =============================================================================
# mk/test.mk – Testing targets
# =============================================================================

##@ Testing

.PHONY: test
test: ## Runs unit and integration tests using Bats
	@printf "%b▶ Running test suite...%b\n" "$(C_CYAN)" "$(C_RESET)"
	@if ! command -v bats > /dev/null; then \
		printf "%b✗ Bats is not installed. Install it via 'brew install bats-core' or 'apt install bats'%b\n" "$(C_RED)" "$(C_RESET)"; \
		exit 1; \
	fi
	@bats tests/
