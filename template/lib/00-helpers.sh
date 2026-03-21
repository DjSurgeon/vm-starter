#!/bin/bash
# =============================================================================
# template/lib/00-helpers.sh – Common utility functions
# =============================================================================

log() { echo -e "\e[1;34m[$(date +'%H:%M:%S')]\e[0m $*"; }
success() { echo -e "\e[1;32m[$(date +'%H:%M:%S')] ✅ $*\e[0m"; }
error() { echo -e "\e[1;31m[$(date +'%H:%M:%S')] ❌ ERROR: $*\e[0m" >&2; exit 1; }

check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Command '$1' not found. Please install it (e.g., sudo apt install $2) and try again."
    fi
}
