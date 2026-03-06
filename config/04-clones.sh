#!/bin/bash
# =============================================================================
# DevPod Configuration – 04-clones.sh
# Purpose: Define hardware resources and naming conventions for project clones.
# =============================================================================

# -----------------------------------------------------------------------------
# WEB CLONE – Your primary development profile
# These values override the base template when creating a web‑type project.
# -----------------------------------------------------------------------------
export WEB_CLONE_RAM_MB="8192"		# RAM in MB (8 GB) – suitable for Node, containers, VS Code server
export WEB_CLONE_CPU="4"			# Number of virtual CPUs
export WEB_CLONE_DISK_MB="81920"	# Disk size in MB (80 GB) – enough for node_modules, build caches

# -----------------------------------------------------------------------------
# NAMING PREFIXES
# Used to generate VM names: e.g., "web-ecommerce", "mobile-androidapp", "desktop-tool"
# -----------------------------------------------------------------------------
export WEB_PREFIX="web"				# Prefix for web projects
export MOBILE_PREFIX="mobile"		# Prefix for mobile projects (Android/iOS)
export DESKTOP_PREFIX="desktop"		# Prefix for desktop/Electron/Rust projects

# -----------------------------------------------------------------------------
# FUTURE EXTENSIONS (placeholders)
# You can add specific resources for mobile and desktop clones later.
# Example:
#   export MOBILE_CLONE_RAM_MB="6144"
#   export MOBILE_CLONE_CPU="4"
#   export MOBILE_CLONE_DISK_MB="60000"
#   export DESKTOP_CLONE_RAM_MB="4096"
#   export DESKTOP_CLONE_CPU="2"
#   export DESKTOP_CLONE_DISK_MB="50000"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - The clone creation script (e.g., projects/clone.sh) reads these variables
#     based on the requested type (--type web).
#   - If a type-specific variable is not defined, it falls back to template values.
#   - The prefixes are used to build the final VM name: "${PREFIX}-${PROJECT_NAME}"
# -----------------------------------------------------------------------------