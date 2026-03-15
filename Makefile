# =============================================================================
# DevPod Makefile – Manage development VM templates and projects
# =============================================================================

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# Extract variables from the modular configuration using shell calls
VAR_LOADER := source config/config.sh >/dev/null 2>&1 && echo
TEMPLATE_NAME := $(shell $(VAR_LOADER) $$TEMPLATE_NAME)
ISO_DIR := $(shell $(VAR_LOADER) $$ISO_DIR)
DISK_IMAGES_DIR := $(shell $(VAR_LOADER) $$DISK_IMAGES_DIR)
ADMIN_USER := $(shell $(VAR_LOADER) $$ADMIN_USER)
SSH_PORT := $(shell $(VAR_LOADER) $$SSH_PORT)

# Colours (portable via printf)
C_RESET  := \033[0m
C_BOLD   := \033[1m
C_GREEN  := \033[32m
C_YELLOW := \033[33m
C_CYAN   := \033[36m
C_BLUE   := \033[34m
C_RED    := \033[31m
C_MAGENTA:= \033[35m

.PHONY: help template project list start stop ssh status check deps clean fclean re

help:
	@printf "$(C_BOLD)DevPod – Development VM Manager$(C_RESET)\n\n"
	@printf "Usage:\n"
	@printf "  $(C_GREEN)make template$(C_RESET)        Create the base template ($(C_CYAN)$(TEMPLATE_NAME)$(C_RESET))\n"
	@printf "  $(C_GREEN)make project$(C_RESET)         Create a new project (interactive)\n"
	@printf "  $(C_GREEN)make project NAME=n TYPE=t$(C_RESET)   Create project with given name and type (web|inception)\n"
	@printf "  $(C_GREEN)make list$(C_RESET)            List all VirtualBox VMs\n"
	@printf "  $(C_GREEN)make start NAME=v$(C_RESET)    Start a VM by name\n"
	@printf "  $(C_GREEN)make stop NAME=v$(C_RESET)     Power off a VM by name\n"
	@printf "  $(C_GREEN)make ssh NAME=v$(C_RESET)      Connect to a VM via SSH (alias from ~/.ssh/config)\n"
	@printf "  $(C_GREEN)make status$(C_RESET)          Show status of template and projects\n"
	@printf "  $(C_GREEN)make check$(C_RESET)           Check system dependencies and configuration\n"
	@printf "  $(C_GREEN)make deps$(C_RESET)            Install required packages (VirtualBox, genisoimage, etc.)\n"
	@printf "  $(C_GREEN)make clean$(C_RESET)           Remove ISOs and seed files (keep VMs)\n"
	@printf "  $(C_GREEN)make fclean$(C_RESET)          Remove everything (VMs, ISOs, seeds) – use with care!\n"
	@printf "  $(C_GREEN)make re$(C_RESET)              Full rebuild (fclean + template)\n\n"

template:
	@printf "$(C_CYAN)▶ Creating base template with user: $(C_BOLD)$${USER_NAME:-$(ADMIN_USER)}$(C_RESET)\n"
	@chmod +x template/create-template.sh
	@ADMIN_USER=$${USER_NAME:-$(ADMIN_USER)} ./template/create-template.sh

project:
	@chmod +x scripts/clone.sh 2>/dev/null || true
	@if [ -z "$${NAME:-}" ] || [ -z "$${TYPE:-}" ]; then \
		read -p "Project name: " PROJECT_NAME; \
		read -p "Project type (web/inception): " PROJECT_TYPE; \
		./scripts/clone.sh "$$PROJECT_NAME" "$$PROJECT_TYPE"; \
	else \
		./scripts/clone.sh "$(NAME)" "$(TYPE)"; \
	fi

list:
	@VBoxManage list vms | column -t

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

re: vclean template
	@printf "$(C_GREEN)✓ Rebuild complete.$(C_RESET)\n"