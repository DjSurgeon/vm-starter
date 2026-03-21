# =============================================================================
# mk/vm-ops.mk – VM operation targets
# =============================================================================

.PHONY: list start stop ssh status info

list:
	@VBoxManage list vms | column -t

info:
	@printf "$(C_CYAN)╔════════════════════════════════════════════════════════════════╗$(C_RESET)\n"
	@printf "$(C_CYAN)║$(C_RESET) $(C_BOLD)DevPod Dashboard$(C_RESET)                                         $(C_CYAN)║$(C_RESET)\n"
	@printf "$(C_CYAN)╠════════════════════════════════════════════════════════════════╣$(C_RESET)\n"
	@# Disk Space
	@disk_free=$$(df -h "$(DISK_IMAGES_DIR)" | tail -1 | awk '{print $$4}'); \
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
	for vm in $$(VBoxManage list runningvms | awk '{print $$1}' | tr -d '"' | grep -E "^(web|inception)-"); do \
		ssh_port=$$(VBoxManage showvminfo "$$vm" --machinereadable | grep "Forwarding(0)" | grep "guestssh" | cut -d, -f4); \
		printf "$(C_CYAN)║$(C_RESET)  $(C_GREEN)%-20s$(C_RESET) $(C_CYAN)│$(C_RESET) SSH Port: %-19s $(C_CYAN)║$(C_RESET)\n" "$$vm" "$$ssh_port"; \
		found=1; \
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

ssh:
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)Error: missing NAME. Use: make ssh NAME=<vm-name>$(C_RESET)\n"; exit 1; \
	fi
	@if [ "$(NAME)" = "$(TEMPLATE_NAME)" ]; then \
		printf "$(C_CYAN)▶ Connecting to base template ($(TEMPLATE_NAME))...$(C_RESET)\n"; \
		ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $(SSH_PORT) $(ADMIN_USER)@127.0.0.1; \
	else \
		printf "$(C_CYAN)▶ Connecting to project '$(NAME)'...$(C_RESET)\n"; \
		ssh $(NAME); \
	fi

status:
	@printf "$(C_CYAN)=== DevPod Status ===$(C_RESET)\n"
	@printf "$(C_BOLD)Template:$(C_RESET)\n"
	@if VBoxManage showvminfo "$(TEMPLATE_NAME)" >/dev/null 2>&1; then \
		state=$$(VBoxManage showvminfo "$(TEMPLATE_NAME)" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "  $(TEMPLATE_NAME): $$state\n"; \
	else \
		printf "  $(TEMPLATE_NAME): $(C_YELLOW)not found (run 'make template')$(C_RESET)\n"; \
	fi
	@printf "$(C_BOLD)Projects:$(C_RESET)\n"
	@found=0; \
	for vm in $$(VBoxManage list vms | awk '{print $$1}' | tr -d '"' | grep -E "^(web|inception)-"); do \
		state=$$(VBoxManage showvminfo "$$vm" --machinereadable 2>/dev/null | grep VMState= | cut -d= -f2 | tr -d '"'); \
		printf "  $$vm: $$state\n"; \
		found=1; \
	done; \
	if [ $$found -eq 0 ]; then \
		printf "  (no projects found)\n"; \
	fi
	@printf "$(C_BOLD)SSH aliases:$(C_RESET)\n"
	@grep -E "^Host (web|inception)-" ~/.ssh/config 2>/dev/null | sed 's/Host /  /' || printf "  (none)\n"
