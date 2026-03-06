#!/bin/bash
# =============================================================================
# DevPod Configuration – 99-functions.sh
# Purpose: Provide utility functions for the configuration system.
# Source order: Must be sourced LAST, after all other config files.
# =============================================================================

# -----------------------------------------------------------------------------
# Marker function – indicates that the configuration has been successfully loaded.
# Scripts can check this by running `devpod_config_loaded` and verifying the
# return code (0 = success). This is useful to ensure that config.sh was sourced
# before using any variables.
# -----------------------------------------------------------------------------
devpod_config_loaded() {
    return 0
}

# -----------------------------------------------------------------------------
# Display a summary of the most important configuration settings.
# Useful for debugging or confirming that variables are set as expected.
# -----------------------------------------------------------------------------
show_config() {
    echo "=== DevPod Configuration ==="
    echo "Template: ${TEMPLATE_NAME} (${TEMPLATE_RAM_MB}MB RAM, ${TEMPLATE_CPU} CPUs)"
    echo "User: ${ADMIN_USER}"
    echo "Hostname: ${TEMPLATE_HOSTNAME}"
    echo "Disk: ${TEMPLATE_DISK_MB}MB (boot: ${PARTITION_BOOT_SIZE_MB}MB)"
    echo "SSH: host port ${SSH_PORT} → VM port ${SSH_VM_PORT}"
    echo "Web Clone: ${WEB_CLONE_RAM_MB}MB RAM, ${WEB_CLONE_CPU} CPUs, ${WEB_CLONE_DISK_MB}MB disk"
    echo "Partitioning: ${FILESYSTEM_ROOT} root, swapfile ${SWAP_SIZE_MB}MB"
    echo "Packages: base ($(echo ${PACKAGES_BASE} | wc -w) items), Docker ($(echo ${PACKAGES_DOCKER} | wc -w) items)"
    echo "============================"
}

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - These functions are intended to be called from other scripts after
#     sourcing config.sh (which in turn sources all 00–99 files).
#   - `devpod_config_loaded` is a simple sanity check; it does nothing but
#     confirms that this file was sourced.
#   - `show_config` prints a human‑readable overview – extend it as needed
#     when new variables are added to the configuration.
# -----------------------------------------------------------------------------