# =============================================================================
# mk/vm-ops.mk – VM operation targets
# =============================================================================

.PHONY: list start stop ssh status info rm

list:
	@VBoxManage list vms | column -t

info:
	@printf "$(C_CYAN)╔════════════════════════════════════════════════════════════════╗$(C_RESET)\n"
	@printf "$(C_CYAN)║$(C_RESET) $(C_BOLD)VM-Starter Dashboard$(C_RESET)                                         $(C_CYAN)║$(C_RESET)\n"
	@printf "$(C_CYAN)╠════════════════════════════════════════════════════════════════╣$(C_RESET)\n"
	@# Disk Space
	@disk_free=$$(df -h "$(DISK_IMAGES_DIR)" 2>/dev/null | tail -1 | awk '{print $$4}') || disk_free="N/A"; \
	printf "$(C_CYAN)║$(C_RESET) $(C_YELLOW)Disk Space Available:$(C_RESET) %-37s $(C_CYAN)║$(C_RESET)\n" "$$disk_free"
	@# Template Status
	@if VBoxManage showvminfo "$(TEMPLATE_NAME)" >/dev/null 2>&1; then \
		state=$$(VBoxManage showvminfo "$(TEMPLATE_NAME)" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "$(C_CYAN)║$(C_RESET) $(C_BLUE)Template:$(C_RESET) %-15s $(C_CYAN)│$(C_RESET) $(C_BLUE)Status:$(C_RESET) %-18s $(C_CYAN)║$(C_RESET)\n" "$(TEMPLATE_NAME)" "$$state"; \
	else \
		printf "$(C_CYAN)║$(C_RESET) $(C_BLUE)Template:$(C_RESET) %-15s $(C_CYAN)│$(C_RESET) $(C_RED)Not Found$(C_RESET) %-20s $(C_CYAN)║$(C_RESET)\n" "$(TEMPLATE_NAME)" ""; \
	fi
	@printf "$(C_CYAN)╠════════════════════════════════════════════════════════════════╣$(C_RESET)\n"
	@printf "$(C_CYAN)║$(C_RESET) $(C_BOLD)Running Projects:$(C_RESET)                                      $(C_CYAN)║$(C_RESET)\n"
	@found=0; \
	for vm in $$(VBoxManage list runningvms | awk '{print $$1}' | tr -d '"'); do \
		ssh_port=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
		if [ -n "$$ssh_port" ]; then \
			printf "$(C_CYAN)║$(C_RESET)  $(C_GREEN)%-20s$(C_RESET) $(C_CYAN)│$(C_RESET) SSH Port: %-19s $(C_CYAN)║$(C_RESET)\n" "$$vm" "$$ssh_port"; \
			found=1; \
		fi \
	done; \
	if [ $$found -eq 0 ]; then \
		printf "$(C_CYAN)║$(C_RESET)  (no projects currently running)                            $(C_CYAN)║$(C_RESET)\n"; \
	fi
	@printf "$(C_CYAN)╚════════════════════════════════════════════════════════════════╝$(C_RESET)\n"

start:
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)Error: missing NAME. Use: make start NAME=<vm-name>$(C_RESET)\n"; exit 1; \
	fi
	@VBoxManage startvm "$(NAME)" --type headless
	@printf "$(C_GREEN)✓ VM '$(NAME)' started.$(C_RESET)\n"

stop:
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)Error: missing NAME. Use: make stop NAME=<vm-name>$(C_RESET)\n"; exit 1; \
	fi
	@VBoxManage controlvm "$(NAME)" acpipowerbutton 2>/dev/null || \
	 VBoxManage controlvm "$(NAME)" poweroff 2>/dev/null || \
	 printf "$(C_YELLOW)⚠ VM '$(NAME)' is not running.$(C_RESET)\n"

rm:
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)Error: missing NAME. Use: make rm NAME=<vm-name>$(C_RESET)\n"; exit 1; \
	fi
	@if ! VBoxManage showvminfo "$(NAME)" >/dev/null 2>&1; then \
		printf "$(C_RED)Error: VM '$(NAME)' does not exist.$(C_RESET)\n"; exit 1; \
	fi
	@if ! echo "$(NAME)" | grep -Eq "^($(TEMPLATE_NAME)|web-|inception-)"; then \
		printf "$(C_RED)Error: VM '$(NAME)' is not a VM-Starter VM. Aborting for safety.$(C_RESET)\n"; exit 1; \
	fi
	@printf "$(C_YELLOW)▶ Deleting VM '$(NAME)'...$(C_RESET)\n"
	@VBoxManage controlvm "$(NAME)" poweroff 2>/dev/null || true
	@VBoxManage unregistervm "$(NAME)" --delete 2>/dev/null || true
	@printf "$(C_YELLOW)▶ Cleaning SSH alias for '$(NAME)'...$(C_RESET)\n"
	@awk -v host="Host $(NAME)" '$$0 == host { skip=1; next } skip && /^Host / { skip=0 } !skip { print }' ~/.ssh/config > ~/.ssh/config.tmp && mv ~/.ssh/config.tmp ~/.ssh/config 2>/dev/null || true
	@printf "$(C_GREEN)✓ VM '$(NAME)' deleted.$(C_RESET)\n"

ssh:
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)Error: missing NAME. Use: make ssh NAME=<vm-name>$(C_RESET)\n"; exit 1; \
	fi
	@# Try to detect the SSH port from VirtualBox port forwarding rules
	@ssh_port=$$(VBoxManage showvminfo "$(NAME)" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
	if [ -n "$$ssh_port" ]; then \
		printf "$(C_CYAN)▶ Connecting to '$(NAME)' on port $$ssh_port...$(C_RESET)\n"; \
		ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $$ssh_port $(ADMIN_USER)@127.0.0.1; \
	else \
		printf "$(C_CYAN)▶ Connecting to project '$(NAME)' via SSH alias...$(C_RESET)\n"; \
		ssh $(NAME); \
	fi

status:
	@printf "$(C_CYAN)=== VM-Starter Status ===$(C_RESET)\n"
	@printf "$(C_BOLD)Template:$(C_RESET)\n"
	@if VBoxManage showvminfo "$(TEMPLATE_NAME)" >/dev/null 2>&1; then \
		state=$$(VBoxManage showvminfo "$(TEMPLATE_NAME)" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "  $(TEMPLATE_NAME): $$state\n"; \
	else \
		printf "  $(TEMPLATE_NAME): $(C_YELLOW)not found (run 'make template')$(C_RESET)\n"; \
	fi
	@printf "$(C_BOLD)Projects:$(C_RESET)\n"
	@found=0; \
	for vm in $$(VBoxManage list vms | awk '{print $$1}' | tr -d '"'); do \
		if [ "$$vm" != "$(TEMPLATE_NAME)" ]; then \
			ssh_port=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep "Forwarding" | grep "guestssh" | cut -d, -f4); \
			if [ -n "$$ssh_port" ]; then \
				state=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep VMState= | cut -d= -f2 | tr -d '"'); \
				printf "  $$vm: $$state (SSH Port: $$ssh_port)\n"; \
				found=1; \
			fi \
		fi \
	done; \
	if [ $$found -eq 0 ]; then \
		printf "  (no projects found)\n"; \
	fi
	@printf "$(C_BOLD)SSH aliases:$(C_RESET)\n"
	@grep -E "^Host " ~/.ssh/config 2>/dev/null | grep -E "(web|inception)-" | sed 's/Host /  /' || printf "  (none)\n"
