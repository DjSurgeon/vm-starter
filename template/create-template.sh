#!/bin/bash
# =============================================================================
# scripts/create-template.sh – Build the base VM template (devpod-base)
# =============================================================================
# Refactored orchestrator for VM template creation.
# =============================================================================

set -e  # Exit immediately if any command fails

# 1. Load central configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh" || { echo "❌ Error: Could not load config.sh"; exit 1; }

# 2. Source modular libraries
for lib in "${SCRIPT_DIR}/lib/"*.sh; do
    source "$lib"
done

# 3. Safety Check
check_existing_template() {
    if VBoxManage showvminfo "${TEMPLATE_NAME}" >/dev/null 2>&1; then
        printf "${C_YELLOW}⚠ Template '${TEMPLATE_NAME}' already exists.${C_RESET}\n"
        read -p "Do you want to overwrite it and start from scratch? [y/N]: " REPLY
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            printf "${C_BLUE}ℹ Operation cancelled. Existing template was preserved.${C_RESET}\n"
            exit 0
        fi
    fi
}

# 3. Orchestration
main() {
    local admin_user="${1:-$ADMIN_USER}"

    check_existing_template
    check_env "${admin_user}"
    manage_iso
    generate_cloud_init
    provision_vm
    install_os
    finalize_template
}

# Run the orchestration
main "$@"
