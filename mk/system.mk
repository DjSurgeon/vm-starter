# =============================================================================
# mk/system.mk – System dependencies and cleanup targets
# =============================================================================

.PHONY: check deps clean vclean fclean

check:
	@printf "$(C_CYAN)▶ Checking system dependencies...$(C_RESET)\n"
	@errors=0; \
	if ! command -v VBoxManage >/dev/null 2>&1; then \
		printf "$(C_RED)✗ VBoxManage not found. Run 'make deps' to install.$(C_RESET)\n"; errors=$$((errors+1)); \
	else printf "$(C_GREEN)✓ VirtualBox installed.$(C_RESET)\n"; fi; \
	if ! command -v genisoimage >/dev/null 2>&1; then \
		printf "$(C_RED)✗ genisoimage not found. Run 'make deps' to install.$(C_RESET)\n"; errors=$$((errors+1)); \
	else printf "$(C_GREEN)✓ genisoimage installed.$(C_RESET)\n"; fi; \
	if [ ! -f ~/.ssh/id_ed25519.pub ] && [ ! -f ~/.ssh/id_rsa.pub ]; then \
		printf "$(C_YELLOW)⚠ No SSH public key found. You may need to generate one (ssh-keygen).$(C_RESET)\n"; \
	else printf "$(C_GREEN)✓ SSH public key found.$(C_RESET)\n"; fi; \
	if ! command -v nc >/dev/null 2>&1; then \
		printf "$(C_YELLOW)⚠ netcat (nc) not found. SSH waiting may be slower.$(C_RESET)\n"; \
	else printf "$(C_GREEN)✓ netcat installed.$(C_RESET)\n"; fi; \
	if [ $$errors -gt 0 ]; then \
		printf "$(C_RED)✗ Some dependencies are missing. Please fix them.$(C_RESET)\n"; exit 1; \
	else printf "$(C_GREEN)✓ All checks passed.$(C_RESET)\n"; fi

deps:
	@printf "$(C_CYAN)▶ Installing dependencies...$(C_RESET)\n"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update -qq; \
		sudo apt-get install -y virtualbox genisoimage curl wget netcat-openbsd; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y VirtualBox genisoimage curl wget nc; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -Sy --noconfirm virtualbox genisoimage curl wget gnu-netcat; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install --cask virtualbox; \
		brew install genisoimage curl wget netcat; \
	else \
		printf "$(C_RED)✗ Unsupported package manager. Please install VirtualBox and genisoimage manually.$(C_RESET)\n"; exit 1; \
	fi
	@printf "$(C_GREEN)✓ Dependencies installed.$(C_RESET)\n"

clean:
	@printf "$(C_YELLOW)▶ Removing temporary seed files and configs...$(C_RESET)\n"
	@rm -f /tmp/seed-*.iso iso/seed-*.iso
	@rm -rf cloud-init/user-data cloud-init/meta-data
	@printf "$(C_GREEN)✓ Clean done.$(C_RESET)\n"

vclean: clean
	@printf "$(C_YELLOW)▶ Removing DevPod VMs (keeping ISO)...$(C_RESET)\n"
	@for vm in $$(VBoxManage list vms | awk '{print $$1}' | tr -d '"' | grep -E "^devpod-base$$|^web-|^inception-"); do \
		printf "  Deleting $$vm...\n"; \
		VBoxManage controlvm "$$vm" poweroff 2>/dev/null || true; \
		VBoxManage unregistervm "$$vm" --delete 2>/dev/null || true; \
	done; \
	rm -rf $(DISK_IMAGES_DIR)/$(TEMPLATE_NAME) 2>/dev/null || true

fclean:
	@printf "$(C_RED)⚠ WARNING: This will delete ALL DevPod VMs and files.$(C_RESET)\n"
	@read -p "Are you sure? (y/N) " REPLY; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		printf "\n$(C_YELLOW)▶ Removing VMs...$(C_RESET)\n"; \
		for vm in $$(VBoxManage list vms | awk '{print $$1}' | tr -d '"' | grep -E "^(devpod-base|web|inception)-"); do \
			printf "  Deleting $$vm...\n"; \
			VBoxManage controlvm "$$vm" poweroff 2>/dev/null || true; \
			VBoxManage unregistervm "$$vm" --delete 2>/dev/null || true; \
		done; \
		printf "$(C_YELLOW)▶ Removing ISO and seed files...$(C_RESET)\n"; \
		if [ -n "$(ISO_DIR)" ] && [ -d "$(ISO_DIR)" ]; then \
			rm -f "$(ISO_DIR)"/*.iso; \
		fi; \
		rm -f /tmp/seed-*.iso; \
		printf "$(C_GREEN)✓ Full clean completed.$(C_RESET)\n"; \
	else \
		printf "\n$(C_YELLOW)Aborted.$(C_RESET)\n"; \
	fi
