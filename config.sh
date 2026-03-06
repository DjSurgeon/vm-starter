#!/bin/bash
# =============================================================================
# DevPod Template - Central Configuration File
# =============================================================================
# ADAPTED from original preseed.cfg (Debian Born2beRoot)
# Main changes:
#   - Debian → Ubuntu 24.04 LTS (noble)
#   - LUKS removed (unnecessary in local dev VM)
#   - LVM simplified (boot + root, no 7 volumes)
#   - Resources defined (RAM/CPU/disk)
#   - Custom SSH port (4222 instead of 22)
#   - Generic user 'dev' (instead of 'dlesieur')
# =============================================================================

# =============================================================================
# SECTION 1: LOCALIZATION (inherited from preseed.cfg)
# =============================================================================

# Locale and keyboard (same as your preseed)
export LOCALE="en_US.UTF-8"
export KEYBOARD_LAYOUT="es"
export TIMEZONE="Europe/Madrid"

# =============================================================================
# SECTION 2: USER ACCOUNTS (adapted from preseed.cfg)
# =============================================================================

# Administrative user (changed from 'dlesieur' to 'dev' for universality)
export ADMIN_USER="dev"
export ADMIN_FULLNAME="Developer"
export ADMIN_PASSWORD="tempuser123"      # Same as your preseed, change later

# Root (keep root access with simple password)
export ROOT_PASSWORD="temproot123"       # Same as your preseed

# =============================================================================
# SECTION 3: BASE TEMPLATE CONFIGURATION (NEW - not in preseed)
# =============================================================================

export TEMPLATE_NAME="devpod-base"
export TEMPLATE_HOSTNAME="devpod-base"

# Template hardware (new values, preseed didn't specify)
export TEMPLATE_RAM_MB="4096"            # 4 GB
export TEMPLATE_CPU="2"                  # 2 cores
export TEMPLATE_DISK_MB="51200"          # 50 GB

# Paths (structure similar to your original project)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DISK_IMAGES_DIR="${BASE_DIR}/disk_images"
export TEMPLATE_DIR="${DISK_IMAGES_DIR}/${TEMPLATE_NAME}"
export TEMPLATE_DISK_PATH="${TEMPLATE_DIR}/${TEMPLATE_NAME}.vdi"

# =============================================================================
# SECTION 4: WEB CLONE CONFIGURATION (NEW - your specific settings)
# =============================================================================

# These values override the template when you create a web clone
export WEB_CLONE_RAM_MB="8192"           # 8 GB (your requirement)
export WEB_CLONE_CPU="4"                 # 4 cores (your requirement)
export WEB_CLONE_DISK_MB="81920"         # 80 GB (your requirement)

# Prefixes for naming clones (new)
export WEB_PREFIX="web"
export MOBILE_PREFIX="mobile"
export DESKTOP_PREFIX="desktop"

# =============================================================================
# SECTION 5: PARTITIONING (ADAPTED from preseed.cfg - SIMPLIFIED)
# =============================================================================

# ORIGINAL preseed.cfg:
#   - Guided - use entire disk and set up encrypted LVM
#   - 7 LVM volumes: root, swap, home, var, srv, tmp, var-log
#   - LUKS passphrase: tempencrypt123
#   - Boot: 500MB ext2
#
# NEW DevPod:
#   - No LUKS (unnecessary local VM)
#   - No complex LVM (administrative overhead)
#   - 2 simple partitions: boot + root

export PARTITION_BOOT_SIZE_MB="1024"     # 1 GB (doubled vs preseed, Ubuntu needs more)
export PARTITION_ROOT_SIZE_MB="-1"       # Rest of the disk (fill remaining)

export FILESYSTEM_BOOT="ext4"            # Changed from ext2 to ext4 (better performance)
export FILESYSTEM_ROOT="ext4"            # Kept

# Swap as a file (more flexible than fixed partition)
export SWAP_SIZE_MB="2048"               # 2 GB swapfile (instead of LVM volume)

# =============================================================================
# SECTION 6: NETWORK AND SSH (ADAPTED from preseed.cfg)
# =============================================================================

# ORIGINAL preseed.cfg:
#   - SSH installed but default port 22
#   - netcfg/choose_interface select auto
#
# NEW DevPod:
#   - Explicit SSH port 4222 (avoid host conflicts)
#   - VirtualBox NAT port forwarding

export SSH_PORT="4222"                   # Host port mapped to VM
export SSH_VM_PORT="22"                  # Internal VM port (standard)

# Additional port forwarding (new, not in preseed)
export HTTP_HOST_PORT="8080"             # For web development servers
export HTTPS_HOST_PORT="8443"            # For local HTTPS

# Ranges for multiple clones (new)
export SSH_PORT_RANGE_START="4222"
export SSH_PORT_RANGE_END="4299"

# SSH hardening (simplified vs your b2b-setup.sh)
export SSH_PERMIT_ROOT_LOGIN="no"        # No root login via SSH
export SSH_PASSWORD_AUTH="no"            # Keys only (after initial setup)

# =============================================================================
# SECTION 7: PACKAGES (ADAPTED from preseed.cfg - REDUCED)
# =============================================================================

# ORIGINAL preseed.cfg installed everything natively:
#   nodejs, npm, golang-go, docker.io, docker-compose, podman,
#   postgresql, redis-server, sqlite3, etc.
#
# PROBLEM: Old versions, hard to update, system pollution
#
# NEW DevPod:
#   - Minimal system + Docker
#   - Node, DBs, etc. via Docker or nvm (controlled versions)

# Base system packages (reduced vs preseed.cfg)
export PACKAGES_BASE="
    openssh-server
    sudo
    curl
    wget
    vim
    nano
    git
    htop
    build-essential
    python3
    python3-pip
    python3-venv
    ca-certificates
    gnupg
    apt-transport-https
    software-properties-common
"

# Docker (the only essential native service)
export PACKAGES_DOCKER="
    docker-ce
    docker-ce-cli
    containerd.io
    docker-compose-plugin
"

# Packages REMOVED vs preseed.cfg (will be installed via Docker):
#   - nodejs, npm → Use nvm or node:20 container
#   - postgresql → postgres:16-alpine container
#   - redis-server → redis:7-alpine container
#   - golang-go → Download official tarball if needed
#   - podman → Removed (Docker is enough)
#   - wordpress, lighttpd, mariadb → Removed (not needed in base)

# =============================================================================
# SECTION 8: WEB STACK AUTO-INSTALLABLE (NEW)
# =============================================================================

# Specific versions (controlled, not Ubuntu repo versions)
export NODE_VERSION="20"                 # Current LTS
export PNPM_VERSION="9"                  # Fast package manager

# Default containers for web projects
export CONTAINER_POSTGRES="postgres:16-alpine"
export CONTAINER_REDIS="redis:7-alpine"
export CONTAINER_NGINX="nginx:alpine"    # Optional for reverse proxy

# =============================================================================
# SECTION 9: POST-INSTALLATION (ADAPTED from preseed.cfg late_command)
# =============================================================================

# ORIGINAL preseed.cfg:
#   - Copied b2b-setup.sh, monitoring.sh, first-boot-setup.sh
#   - Executed b2b-setup.sh in chroot
#   - Installed global npm packages (eslint, prettier, snyk)
#   - Installed pip packages (ruff, checkov, sqlfluff)
#   - Installed golangci-lint, helm
#   - Generated SSH keys for dlesieur
#
# NEW DevPod:
#   - Simplified scripts: setup-base.sh, setup-web.sh
#   - No massive global installs (each project defines its own deps)
#   - SSH keys injected from host (not generated inside VM)

# Post-installation scripts (new, replace b2b-setup.sh)
export SCRIPT_SETUP_BASE="setup-base.sh"       # Configures SSH, Docker, user
export SCRIPT_SETUP_WEB="setup-web.sh"         # Installs Node, pnpm (only web clones)

# ISO scripts directory (similar structure to your preseed)
export ISO_SCRIPTS_DIR="scripts"

# =============================================================================
# SECTION 10: VS CODE AND SSH (NEW - not in preseed)
# =============================================================================

# Optimizations for VS Code Remote SSH (based on your SSH_VSCODE_FIX.md)
export VSCODE_USE_LOCAL_SERVER="false"
export VSCODE_ENABLE_DYNAMIC_FORWARDING="false"
export VSCODE_CONNECT_TIMEOUT="60"

# SSH keepalives (avoid VirtualBox NAT timeout)
export SSH_KEEPALIVE_INTERVAL="60"
export SSH_KEEPALIVE_COUNTMAX="3"

# =============================================================================
# SECTION 11: LOGGING AND UTILITIES (NEW)
# =============================================================================

export LOG_LEVEL="INFO"
export LOGS_DIR="${BASE_DIR}/logs"
export LOG_FILE="${LOGS_DIR}/devpod.log"

# Output colors
export USE_COLORS="true"

# =============================================================================
# SECTION 12: BEHAVIOR (NEW)
# =============================================================================

export AUTO_START_CLONE="true"
export WAIT_FOR_SSH="true"
export SSH_WAIT_TIMEOUT="120"

# =============================================================================
# UTILITY FUNCTIONS (NEW)
# =============================================================================

# Validate correct loading
devpod_config_loaded() { return 0; }

# Show configuration
show_config() {
    echo "=== DevPod Configuration (adapted from preseed.cfg) ==="
    echo "Template: ${TEMPLATE_NAME} (${TEMPLATE_RAM_MB}MB RAM, ${TEMPLATE_CPU} CPUs)"
    echo "User: ${ADMIN_USER} (password: ${ADMIN_PASSWORD})"
    echo "Hostname: ${TEMPLATE_HOSTNAME}"
    echo "Disk: ${TEMPLATE_DISK_MB}MB (boot: ${PARTITION_BOOT_SIZE_MB}MB, rest root)"
    echo "SSH: port ${SSH_PORT} (host) → ${SSH_VM_PORT} (VM)"
    echo "Web Clone: ${WEB_CLONE_RAM_MB}MB RAM, ${WEB_CLONE_CPU} CPUs, ${WEB_CLONE_DISK_MB}MB disk"
    echo "Partitioning: NO LUKS, NO complex LVM (vs original preseed)"
    echo "Packages: Minimal + Docker (vs native packages in preseed)"
    echo "======================================================"
}

# export -f devpod_config_loaded
# export -f show_config

# =============================================================================
# END OF FILE
# =============================================================================