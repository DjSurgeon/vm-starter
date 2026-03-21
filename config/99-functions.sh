#!/bin/bash
# =============================================================================
# config/99-functions.sh – Shared system-wide functions
# =============================================================================

# -----------------------------------------------------------------------------
# Marker function to confirm config loading
# -----------------------------------------------------------------------------
devpod_config_loaded() { return 0; }

# -----------------------------------------------------------------------------
# 1. UI & Logging Functions
# -----------------------------------------------------------------------------
log()     { echo -e "${C_BLUE}[$(date +'%H:%M:%S')]${C_RESET} $*"; }
success() { echo -e "${C_GREEN}[$(date +'%H:%M:%S')] ✅ $*{C_RESET}"; }
warn()    { echo -e "${C_YELLOW}[$(date +'%H:%M:%S')] ⚠ $*{C_RESET}"; }
error()   { echo -e "${C_RED}[$(date +'%H:%M:%S')] ❌ ERROR: $*{C_RESET}" >&2; exit 1; }
info()    { echo -e "${C_CYAN}[$(date +'%H:%M:%S')] ℹ $*{C_RESET}"; }

# -----------------------------------------------------------------------------
# 2. Spinner (Reusable)
# -----------------------------------------------------------------------------
# Usage: long_command & show_spinner $! "Text..."
show_spinner() {
    local pid=$1
    local msg=$2
    local spin_chars="/-\|"
    local spin_idx=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${C_YELLOW}[%c] %s${C_RESET}" "${spin_chars:$spin_idx:1}" "$msg"
        spin_idx=$(( (spin_idx + 1) % 4 ))
        sleep 0.5
    done
    printf "\r\033[K" # Clear the line when done
}

# -----------------------------------------------------------------------------
# 3. Command Checker
# -----------------------------------------------------------------------------
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Command '$1' not found. Please install it (e.g., sudo apt install $2) and try again."
    fi
}

# -----------------------------------------------------------------------------
# 4. Configuration Summary
# -----------------------------------------------------------------------------
show_config() {
    printf "${C_CYAN}=== DevPod Configuration ===${C_RESET}\n"
    printf "  ${C_BOLD}Template:${C_RESET} ${TEMPLATE_NAME} (${TEMPLATE_RAM_MB}MB RAM, ${TEMPLATE_CPU} CPUs)\n"
    printf "  ${C_BOLD}User:${C_RESET}     ${ADMIN_USER}\n"
    printf "  ${C_BOLD}Hostname:${C_RESET} ${TEMPLATE_HOSTNAME}\n"
    printf "  ${C_BOLD}SSH:${C_RESET}      host port ${SSH_PORT} → VM port ${SSH_VM_PORT}\n"
    printf "  ${C_BOLD}Disk:${C_RESET}     ${TEMPLATE_DISK_MB}MB (boot: ${PARTITION_BOOT_SIZE_MB}MB)\n"
    printf "${C_CYAN}===========================${C_RESET}\n"
}
