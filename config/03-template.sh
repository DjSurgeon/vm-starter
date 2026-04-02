#!/bin/bash
# =============================================================================
# DevPod Configuration – 03-template.sh
# Purpose: Define hardware resources and paths for the base VM template.
# =============================================================================

# -----------------------------------------------------------------------------
# Base template identification
# -----------------------------------------------------------------------------
export TEMPLATE_NAME="${TEMPLATE_NAME:-devpod-base}"
export TEMPLATE_HOSTNAME="${TEMPLATE_HOSTNAME:-devpod-base}"

# -----------------------------------------------------------------------------
# VirtualBox VM Metadata and Controllers
# -----------------------------------------------------------------------------
export TEMPLATE_OSTYPE="${TEMPLATE_OSTYPE:-Ubuntu_64}"
export CONTROLLER_SATA="SATA Controller"
export CONTROLLER_IDE="IDE Controller"

# -----------------------------------------------------------------------------
# Hardware resources allocated to the template
# -----------------------------------------------------------------------------
export TEMPLATE_RAM_MB="${TEMPLATE_RAM_MB:-4096}"
export TEMPLATE_CPU="${TEMPLATE_CPU:-2}"
export TEMPLATE_DISK_MB="${TEMPLATE_DISK_MB:-30720}"

# -----------------------------------------------------------------------------
# Template‑specific directory and disk image path
# -----------------------------------------------------------------------------
# These rely on DISK_IMAGES_DIR defined in 00-init.sh
TEMPLATE_DIR="${DISK_IMAGES_DIR}/${TEMPLATE_NAME}"
export TEMPLATE_DIR
export TEMPLATE_DISK_PATH="${TEMPLATE_DIR}/${TEMPLATE_NAME}.vdi"

# Ensure the template directory exists (will be created if missing)
mkdir -p "$TEMPLATE_DIR"

# -----------------------------------------------------------------------------
# Usage notes:
#   - These values are used by template/create-template.sh to create the VM.
#   - When cloning a project, resources can be overridden by type‑specific
#     settings (e.g., WEB_CLONE_RAM_MB from 04-clones.sh).
#   - Changing these after the template is created does not affect existing VMs;
#     you must recreate the template.
# -----------------------------------------------------------------------------