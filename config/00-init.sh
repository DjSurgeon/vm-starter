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
# Distro Selection (Defaults to Ubuntu)
# -----------------------------------------------------------------------------
export SELECTED_DISTRO="${SELECTED_DISTRO:-ubuntu}" # ubuntu or debian

# -----------------------------------------------------------------------------
# Define all important directory paths used throughout the project.
# -----------------------------------------------------------------------------
# Store large binaries (VMs and ISOs) in the user's home directory to keep the repo clean.
export DEVPOD_ROOT="${HOME}/.devpod"
DISK_IMAGES_DIR="${DEVPOD_ROOT}/vms"			# VDI files for VMs
ISO_DIR="${DEVPOD_ROOT}/iso"					# Downloaded ISOs

# Keep configuration-related temporary files and logs in the project root (or also move if preferred)
LOGS_DIR="${BASE_DIR}/logs"						# Log files
SCRIPTS_DIR="${BASE_DIR}/scripts"				# Post-install scripts
CLOUD_INIT_DIR="${BASE_DIR}/cloud-init"			# Generated cloud-init/preseed files
PRESEED_DIR="${BASE_DIR}/preseeds"				# Folder for preseed.cfg

# -----------------------------------------------------------------------------
# ISO Sources
# -----------------------------------------------------------------------------
# Ubuntu (Noble Numbat 24.04.4 LTS)
export UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso"
export UBUNTU_ISO_FILENAME="ubuntu-24.04.4-server.iso"

# Debian 13 (Trixie)
export DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
export DEBIAN_ISO_FILENAME="debian-13-netinst.iso"

# Active ISO Path (Determined by SELECTED_DISTRO)
if [ "$SELECTED_DISTRO" = "debian" ]; then
    export ISO_URL="$DEBIAN_ISO_URL"
    export ISO_FILENAME="$DEBIAN_ISO_FILENAME"
else
    export ISO_URL="$UBUNTU_ISO_URL"
    export ISO_FILENAME="$UBUNTU_ISO_FILENAME"
fi
export ISO_PATH="${ISO_DIR}/${ISO_FILENAME}"

# -----------------------------------------------------------------------------
# Ensure every directory exists (create if missing).
# -----------------------------------------------------------------------------
mkdir -p	"$DISK_IMAGES_DIR" \
			"$LOGS_DIR" \
			"$ISO_DIR" \
			"$SCRIPTS_DIR" \
			"$CLOUD_INIT_DIR" \
			"$PRESEED_DIR"

# -----------------------------------------------------------------------------
# Optional: Export variables so they are available in subshells.
# -----------------------------------------------------------------------------
export CONFIG_DIR BASE_DIR
export DISK_IMAGES_DIR LOGS_DIR ISO_DIR SCRIPTS_DIR CLOUD_INIT_DIR PRESEED_DIR