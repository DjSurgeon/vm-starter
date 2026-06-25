# =============================================================================
# mk/vm-ops.mk – VM operation targets
# =============================================================================

##@ VM Operations

.PHONY: list start stop ssh status info rm

list: ## Lists all VirtualBox VMs
	@VBoxManage list vms | column -t

info: ## Shows a visual dashboard with disk, VMs, and ports status
	@printf "%b╔════════════════════════════════════════════════════════════════╗%b\n" "$(C_CYAN)" "$(C_RESET)"
	@printf "%b║%b %bVM-Starter Dashboard%b                                         %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_BOLD)" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)"
	@printf "%b╠════════════════════════════════════════════════════════════════╣%b\n" "$(C_CYAN)" "$(C_RESET)"
	@# Disk Space
	@disk_free=$$(df -h "$(DISK_IMAGES_DIR)" 2>/dev/null | tail -1 | awk '{print $$4}') || disk_free="N/A"; \
	printf "%b║%b %bDisk Space Available:%b %-37s %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_YELLOW)" "$(C_RESET)" "$$disk_free" "$(C_CYAN)" "$(C_RESET)"
	@# Template Status
	@if VBoxManage showvminfo "$(TEMPLATE_NAME)" >/dev/null 2>&1; then \
		state=$$(VBoxManage showvminfo "$(TEMPLATE_NAME)" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "%b║%b %bTemplate:%b %-15s %b│%b %bStatus:%b %-18s %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_BLUE)" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)" "$(C_BLUE)" "$(C_RESET)" "$(TEMPLATE_NAME)" "$$state" "$(C_CYAN)" "$(C_RESET)"; \
	else \
		printf "%b║%b %bTemplate:%b %-15s %b│%b %bNot Found%b %-20s %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_BLUE)" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)" "$(C_RED)" "$(C_RESET)" "$(TEMPLATE_NAME)" "" "$(C_CYAN)" "$(C_RESET)"; \
	fi
	@printf "%b╠════════════════════════════════════════════════════════════════╣%b\n" "$(C_CYAN)" "$(C_RESET)"
	@printf "%b║%b %bRunning Projects:%b                                      %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_BOLD)" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)"
	@found=0; \
	for vm in $$(VBoxManage list runningvms | awk '{print $$1}' | tr -d '"'); do \
		ssh_port=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
		if [ -n "$$ssh_port" ]; then \
			printf "%b║%b  %b%-20s%b %b│%b SSH Port: %-19s %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_GREEN)" "$$vm" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)" "$$ssh_port" "$(C_CYAN)" "$(C_RESET)"; \
			found=1; \
		fi \
	done; \
	if [ $$found -eq 0 ]; then \
		printf "%b║%b  (no projects currently running)                            %b║%b\n" "$(C_CYAN)" "$(C_RESET)" "$(C_CYAN)" "$(C_RESET)"; \
	fi
	@printf "%b╚════════════════════════════════════════════════════════════════╝%b\n" "$(C_CYAN)" "$(C_RESET)"

start: ## Starts a VM by name (make start NAME=foo)
	@if [ -z "$(NAME)" ]; then \
		printf "%bError: missing NAME. Use: make start NAME=<vm-name>%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	fi
	@VBoxManage startvm "$(NAME)" --type headless
	@printf "%b✓ VM '%s' started.%b\n" "$(C_GREEN)" "$(NAME)" "$(C_RESET)"

stop: ## Safely powers off a VM (make stop NAME=foo)
	@if [ -z "$(NAME)" ]; then \
		printf "%bError: missing NAME. Use: make stop NAME=<vm-name>%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	fi
	@if VBoxManage controlvm "$(NAME)" acpipowerbutton 2>/dev/null || VBoxManage controlvm "$(NAME)" poweroff 2>/dev/null; then \
	 :; \
	else \
	 printf "%b⚠ VM '%s' is not running.%b\n" "$(C_YELLOW)" "$(NAME)" "$(C_RESET)"; \
	fi

rm: ## Completely removes a VM and cleans its SSH alias (make rm NAME=foo)
	@if [ -z "$(NAME)" ]; then \
		printf "%bError: missing NAME. Use: make rm NAME=<vm-name>%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	fi
	@if ! VBoxManage showvminfo "$(NAME)" >/dev/null 2>&1; then \
		printf "%bError: VM '%s' does not exist.%b\n" "$(C_RED)" "$(NAME)" "$(C_RESET)"; exit 1; \
	fi
	@if ! echo "$(NAME)" | grep -Eq "^($(TEMPLATE_NAME)|web-|inception-)"; then \
		printf "%bError: VM '%s' is not a VM-Starter VM. Aborting for safety.%b\n" "$(C_RED)" "$(NAME)" "$(C_RESET)"; exit 1; \
	fi
	@printf "%b▶ Deleting VM '%s'...%b\n" "$(C_YELLOW)" "$(NAME)" "$(C_RESET)"
	@VBoxManage controlvm "$(NAME)" poweroff 2>/dev/null || true
	@VBoxManage unregistervm "$(NAME)" --delete 2>/dev/null || true
	@printf "%b▶ Cleaning SSH alias for '%s'...%b\n" "$(C_YELLOW)" "$(NAME)" "$(C_RESET)"
	@perl -0777 -pi -e 's/\nHost $(NAME).*?(?=\nHost |\z)//gs' ~/.ssh/config 2>/dev/null || true
	@printf "%b✓ VM '%s' deleted.%b\n" "$(C_GREEN)" "$(NAME)" "$(C_RESET)"

ssh: ## Connects to a VM via SSH (make ssh NAME=foo)
	@if [ -z "$(NAME)" ]; then \
		printf "%bError: missing NAME. Use: make ssh NAME=<vm-name>%b\n" "$(C_RED)" "$(C_RESET)"; exit 1; \
	fi
	@ssh_port=$$(VBoxManage showvminfo "$(NAME)" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
	if [ -n "$$ssh_port" ]; then \
		printf "%b▶ Connecting to '%s' on port $$ssh_port...%b\n" "$(C_CYAN)" "$(NAME)" "$(C_RESET)"; \
		ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $$ssh_port $(ADMIN_USER)@127.0.0.1; \
	else \
		printf "%b▶ Connecting to project '%s' via SSH alias...%b\n" "$(C_CYAN)" "$(NAME)" "$(C_RESET)"; \
		ssh $(NAME); \
	fi

status: ## Shows detailed status of the template and projects
	@printf "%b=== VM-Starter Status ===%b\n" "$(C_CYAN)" "$(C_RESET)"
	@printf "%bTemplate:%b\n" "$(C_BOLD)" "$(C_RESET)"
	@if VBoxManage showvminfo "$(TEMPLATE_NAME)" >/dev/null 2>&1; then \
		state=$$(VBoxManage showvminfo "$(TEMPLATE_NAME)" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "  %s: %s\n" "$(TEMPLATE_NAME)" "$$state"; \
	else \
		printf "  %s: %bnot found (run 'make template')%b\n" "$(TEMPLATE_NAME)" "$(C_YELLOW)" "$(C_RESET)"; \
	fi
	@printf "%bProjects:%b\n" "$(C_BOLD)" "$(C_RESET)"
	@found=0; \
	for vm in $$(VBoxManage list vms | awk '{print $$1}' | tr -d '"'); do \
		if [ "$$vm" != "$(TEMPLATE_NAME)" ]; then \
			ssh_port=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
			if [ -n "$$ssh_port" ]; then \
				state=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep VMState= | cut -d= -f2 | tr -d '"'); \
				printf "  %s: %s (SSH Port: %s)\n" "$$vm" "$$state" "$$ssh_port"; \
				found=1; \
			fi \
		fi \
	done; \
	if [ $$found -eq 0 ]; then \
		printf "  (no projects found)\n"; \
	fi
	@printf "%bSSH aliases:%b\n" "$(C_BOLD)" "$(C_RESET)"
	@grep -E "^Host " ~/.ssh/config 2>/dev/null | grep -E "(web|inception)-" | sed 's/Host /  /' || printf "  (none)\n"
