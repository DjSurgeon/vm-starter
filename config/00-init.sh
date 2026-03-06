#!/bin/bash
# =============================================================================
# DevPod Configuration – 00-init.sh
# Purpose: Initialize base paths and create required directories.
# Source order: This file should be sourced first by config.sh.
# =============================================================================

# Determine the absolute path of the configuration directory.
# BASH_SOURCE[0] points to this file, even when sourced.
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The project root is one level above config/
BASE_DIR="$(dirname "$CONFIG_DIR")"

# -----------------------------------------------------------------------------
# Define all important directory paths used throughout the project.
# -----------------------------------------------------------------------------
DISK_IMAGES_DIR="${BASE_DIR}/disk_images"		# VDI files for VMs
LOGS_DIR="${BASE_DIR}/logs"						# Log files
ISO_DIR="${BASE_DIR}/iso"						# Downloaded Ubuntu ISO
SCRIPTS_DIR="${BASE_DIR}/scripts"				# Post‑install scripts
CLOUD_INIT_DIR="${BASE_DIR}/cloud-init"			# Generated cloud‑init files

# -----------------------------------------------------------------------------
# Ensure every directory exists (create if missing).
# -----------------------------------------------------------------------------
mkdir -p	"$DISK_IMAGES_DIR" \
			"$LOGS_DIR" \
			"$ISO_DIR" \
			"$SCRIPTS_DIR" \
			"$CLOUD_INIT_DIR"

# -----------------------------------------------------------------------------
# Optional: Export variables so they are available in subshells.
# -----------------------------------------------------------------------------
export CONFIG_DIR BASE_DIR
export DISK_IMAGES_DIR LOGS_DIR ISO_DIR SCRIPTS_DIR CLOUD_INIT_DIR