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
# Store large binaries (VMs and ISOs) in the user's home directory to keep the repo clean.
export DEVPOD_ROOT="${HOME}/.devpod"
DISK_IMAGES_DIR="${DEVPOD_ROOT}/vms"			# VDI files for VMs
ISO_DIR="${DEVPOD_ROOT}/iso"					# Downloaded Ubuntu ISO

# Keep configuration-related temporary files and logs in the project root (or also move if preferred)
LOGS_DIR="${BASE_DIR}/logs"						# Log files
SCRIPTS_DIR="${BASE_DIR}/scripts"				# Post-install scripts
CLOUD_INIT_DIR="${BASE_DIR}/cloud-init"			# Generated cloud-init files

# -----------------------------------------------------------------------------
# Ubuntu ISO Source (Noble Numbat 24.04.1 LTS)
# -----------------------------------------------------------------------------
export UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04.1/ubuntu-24.04.1-live-server-amd64.iso"
export UBUNTU_ISO_FILENAME="ubuntu-24.04-server.iso"
export UBUNTU_ISO_PATH="${ISO_DIR}/${UBUNTU_ISO_FILENAME}"

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