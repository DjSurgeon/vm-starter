#!/bin/bash
# =============================================================================
# DevPod Configuration – 04-clones.sh
# Purpose: Define hardware resources and naming for different project types.
#          Supports two main modes: "dev" (modern web) and "inception" (42 project).
# Source order: Should be sourced after 00-init.sh (uses ADMIN_USER from 02-users.sh).
# =============================================================================

# -----------------------------------------------------------------------------
# Operation modes – used by clone scripts to select the appropriate resource profile.
# -----------------------------------------------------------------------------
export MODE_DEV="dev"               # Modern web development (Node, containers, heavy)
export MODE_INCEPTION="inception"    # 42 Inception project (lightweight, specific structure)

# Default mode when creating a new clone (can be overridden by --type flag)
export DEFAULT_CLONE_MODE="${MODE_DEV}"

# -----------------------------------------------------------------------------
# DEV MODE – Web development profile (your primary use case)
# These values override the base template when creating a web‑type project.
# -----------------------------------------------------------------------------
export WEB_CLONE_RAM_MB="8192"      # RAM in MB (8 GB) – suitable for Node, containers, VS Code server
export WEB_CLONE_CPU="4"             # Number of virtual CPUs
export WEB_CLONE_DISK_MB="81920"     # Disk size in MB (80 GB) – enough for node_modules, build caches

# -----------------------------------------------------------------------------
# INCEPTION MODE – 42 project specific resources
# Lighter footprint, but must accommodate Docker volumes under /home/dev/data
# -----------------------------------------------------------------------------
export INCEPTION_CLONE_RAM_MB="4096"    # RAM in MB (4 GB) – sufficient for Inception services
export INCEPTION_CLONE_CPU="2"           # Number of virtual CPUs
export INCEPTION_CLONE_DISK_MB="20480"   # Disk size in MB (20 GB) – for Docker volumes and images

# -----------------------------------------------------------------------------
# NAMING PREFIXES
# Used to generate VM names: e.g., "web-ecommerce", "inception-42", "mobile-app", "desktop-tool"
# -----------------------------------------------------------------------------
export WEB_PREFIX="web"                # Prefix for web projects
export INCEPTION_PREFIX="inception"    # Prefix for 42 Inception projects
export MOBILE_PREFIX="mobile"          # Prefix for mobile projects (Android/iOS) – future use
export DESKTOP_PREFIX="desktop"        # Prefix for desktop/Electron/Rust projects – future use

# -----------------------------------------------------------------------------
# INCEPTION SPECIFIC PATHS
# The project requires volumes to be stored in /home/<user>/data on the host machine.
# We use the ADMIN_USER variable (from 02-users.sh) to build the correct path.
# This directory will be created inside the VM, not on the physical host.
# -----------------------------------------------------------------------------
export INCEPTION_DATA_DIR="/home/${ADMIN_USER}/data"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - The clone script (projects/clone.sh) reads these variables based on the
#     requested mode (--type MODE). If a mode‑specific variable is not defined,
#     it falls back to template values.
#   - The INCEPTION_DATA_DIR is used by the inception setup script to create
#     the required subdirectories (wordpress, mariadb) and to configure bind
#     mounts in docker‑compose.
#   - Resource values are chosen to balance performance and disk usage; they
#     can be adjusted here without touching other scripts.
#   - Future modes (mobile, desktop) can be added by defining their own
#     *_CLONE_RAM_* etc. variables and prefixes.
# -----------------------------------------------------------------------------