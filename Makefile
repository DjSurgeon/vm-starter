# =============================================================================
# DevPod Makefile – Modular Entry Point
# =============================================================================

# 1. Include modular components
include mk/config.mk
include mk/vm-ops.mk
include mk/setup.mk
include mk/system.mk

# 2. Default target
.DEFAULT_GOAL := help

# 3. Help target
help:
	@printf "$(C_BOLD)DevPod – Development VM Manager$(C_RESET)\n\n"
	@printf "Usage:\n"
	@printf "  $(C_GREEN)make create$(C_RESET)         Launch the interactive wizard (Vite-like UI)\n"
	@printf "  $(C_GREEN)make info$(C_RESET)           Show visual dashboard (Disk, VMs, Ports)\n"
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

# 4. Wizard target
create:
	@chmod +x scripts/wizard.sh
	@./scripts/wizard.sh
