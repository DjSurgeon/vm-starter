# =============================================================================
# mk/system.mk – System dependencies and cleanup targets
# =============================================================================

##@ System & Cleanup

.PHONY: check deps clean vclean fclean

check: ## Checks system dependencies (VirtualBox, genisoimage, etc.)
	@printf "%b▶ Checking system dependencies...%b\n" "$(C_CYAN)" "$(C_RESET)"
	@errors=0; \
	if ! command -v VBoxManage >/dev/null 2>&1; then \
		printf "%b✗ VBoxManage not found. Run 'make deps' to install.%b\n" "$(C_RED)" "$(C_RESET)"; errors=$$((errors+1)); \
	else printf "%b✓ VirtualBox installed.%b\n" "$(C_GREEN)" "$(C_RESET)"; fi; \
	if command -v genisoimage >/dev/null 2>&1 || command -v mkisofs >/dev/null 2>&1; then \
		printf "%b✓ ISO creation tool (genisoimage/mkisofs) installed.%b\n" "$(C_GREEN)" "$(C_RESET)"; \
	else \
		printf "%b✗ ISO creation tool not found. Run 'make deps' to install genisoimage or mkisofs.%b\n" "$(C_RED)" "$(C_RESET)"; errors=$$((errors+1)); \
	fi; \
	if [ ! -f ~/.ssh/id_ed25519.pub ] && [ ! -f ~/.ssh/id_rsa.pub ]; then \
		printf "%b⚠ No SSH public key found. You may need to generate one (ssh-keygen).%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
	else printf "%b✓ SSH public key found.%b\n" "$(C_GREEN)" "$(C_RESET)"; fi; \
	if ! command -v nc >/dev/null 2>&1; then \
		printf "%b⚠ netcat (nc) not found. SSH waiting may be slower.%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
	else printf "%b✓ netcat installed.%b\n" "$(C_GREEN)" "$(C_RESET)"; fi; \
	if [ $$errors -gt 0 ]; then \
		printf "%b✗ Some dependencies are missing. Please fix them.%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	else printf "%b✓ All checks passed.%b\n" "$(C_GREEN)" "$(C_RESET)"; fi

deps: ## Installs required packages on the host
	@printf "%b▶ Installing dependencies...%b\n" "$(C_CYAN)" "$(C_RESET)"
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
		printf "%b✗ Unsupported package manager. Please install VirtualBox and genisoimage manually.%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	fi
	@printf "%b✓ Dependencies installed.%b\n" "$(C_GREEN)" "$(C_RESET)"

clean: ## Removes temporary seed files and ISOs (keeps VMs)
	@printf "%b▶ Removing temporary seed files and configs...%b\n" "$(C_YELLOW)" "$(C_RESET)"
	@iso_dir="$(ISO_DIR)"; rm -f /tmp/seed-*.iso "$${iso_dir:?ISO_DIR variable is empty!}"/seed-*.iso
	@rm -rf cloud-init/user-data cloud-init/meta-data
	@# Remove legacy local directories if they still exist in the repo
	@rm -rf iso/ disk_images/
	@printf "%b✓ Clean done.%b\n" "$(C_GREEN)" "$(C_RESET)"

vclean: clean ## Removes project VMs (keeps base ISO)
	@printf "%b▶ Forgetting inaccessible VMs...%b\n" "$(C_YELLOW)" "$(C_RESET)"
	@if command -v VBoxManage >/dev/null 2>&1; then \
		VBoxManage list vms | grep '"<inaccessible>"' | awk '{print $$2}' | tr -d '{}' | while read uuid; do \
			VBoxManage unregistervm "$$uuid" 2>/dev/null || true; \
		done || true; \
	else \
		printf "  %b⚠ VBoxManage not found. Skipping VM cleanup.%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
	fi
	@printf "%b▶ Removing VM-Starter VMs (keeping ISO)...%b\n" "$(C_YELLOW)" "$(C_RESET)"
	@# Identify VM-Starter VMs: either by name prefix or by having a 'guestssh' rule
	@if command -v VBoxManage >/dev/null 2>&1; then \
		VBoxManage list vms | sed 's/"\(.*\)".*/\1/' | while read -r vm; do \
			if [[ "$$vm" =~ ^($(TEMPLATE_NAME)|web-|inception-) ]]; then \
				printf "  Deleting %s...\n" "$$vm"; \
				VBoxManage controlvm "$$vm" poweroff 2>/dev/null || true; \
				VBoxManage unregistervm "$$vm" --delete 2>/dev/null || true; \
			fi \
		done; \
	fi
	@disk_dir="$(DISK_IMAGES_DIR)"; rm -rf "$${disk_dir:?DISK_IMAGES_DIR variable is empty!}" 2>/dev/null || true
	@printf "%b▶ Cleaning SSH aliases for VM-Starter VMs...%b\n" "$(C_YELLOW)" "$(C_RESET)"
	@perl -0777 -pi -e 's/\nHost (web-|inception-).*?(?=\nHost |\z)//gs' ~/.ssh/config 2>/dev/null || true

fclean: ## Completely removes everything (VMs, ISOs, seeds). Dangerous!
	@printf "%b⚠ WARNING: This will delete ALL VM-Starter VMs and binary files.%b\n" "$(C_RED)" "$(C_RESET)"
	@read -p "Are you sure? (y/N) " REPLY; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		printf "\n%b▶ Forgetting inaccessible VMs...%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
		if command -v VBoxManage >/dev/null 2>&1; then \
			VBoxManage list vms | grep '"<inaccessible>"' | awk '{print $$2}' | tr -d '{}' | while read uuid; do \
				VBoxManage unregistervm "$$uuid" 2>/dev/null || true; \
			done || true; \
		else \
			printf "  %b⚠ VBoxManage not found. Skipping VM cleanup.%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
		fi; \
		printf "%b▶ Removing VMs...%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
		if command -v VBoxManage >/dev/null 2>&1; then \
			VBoxManage list vms | sed 's/"\(.*\)".*/\1/' | while read -r vm; do \
				if [[ "$$vm" =~ ^($(TEMPLATE_NAME)|web-|inception-) ]]; then \
					printf "  Deleting %s...\n" "$$vm"; \
					VBoxManage controlvm "$$vm" poweroff 2>/dev/null || true; \
					VBoxManage unregistervm "$$vm" --delete 2>/dev/null || true; \
				fi \
			done; \
		fi; \
		printf "%b▶ Removing ISO and binary root...%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
		iso_dir="$(ISO_DIR)"; rm -rf "$${iso_dir:?ISO_DIR variable is empty!}" 2>/dev/null || true; \
		dev_root="$(DEVPOD_ROOT)"; rm -rf "$${dev_root:?DEVPOD_ROOT variable is empty!}" 2>/dev/null || true; \
		rm -f /tmp/seed-*.iso; \
		printf "%b▶ Cleaning SSH aliases for VM-Starter VMs...%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
		perl -0777 -pi -e 's/\nHost (web-|inception-).*?(?=\nHost |\z)//gs' ~/.ssh/config 2>/dev/null || true; \
		printf "%b✓ Full clean completed.%b\n" "$(C_GREEN)" "$(C_RESET)"; \
	else \
		printf "\n%bAborted.%b\n" "$(C_YELLOW)" "$(C_RESET)"; \
	fi
