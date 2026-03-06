#!/bin/bash
# =============================================================================
# DevPod Configuration – 09-postinstall.sh
# Purpose: Define names of post‑installation scripts and their location on the ISO.
# Source order: Should be sourced after 00-init.sh (no direct dependencies).
# =============================================================================

# -----------------------------------------------------------------------------
# Base setup script – common configuration for every VM (template and clones).
# This script is executed once during first boot (via cloud‑init or systemd).
# -----------------------------------------------------------------------------
export SCRIPT_SETUP_BASE="setup-base.sh"

# -----------------------------------------------------------------------------
# Web‑specific setup script – runs only for web‑type clones.
# Installs Node.js, pnpm, and prepares the environment for web development.
# -----------------------------------------------------------------------------
export SCRIPT_SETUP_WEB="setup-web.sh"

# -----------------------------------------------------------------------------
# Directory inside the custom ISO where the post‑install scripts are placed.
# The ISO generator (e.g., create-template.sh) copies scripts from the local
# SCRIPTS_DIR (defined in 00-init.sh) into this folder on the ISO.
# -----------------------------------------------------------------------------
export ISO_SCRIPTS_DIR="scripts"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - These script names are referenced by cloud‑init user-data (runcmd) or by
#     the first‑boot service to invoke the appropriate configuration steps.
#   - SCRIPT_SETUP_BASE should be idempotent – it can be safely rerun.
#   - SCRIPT_SETUP_WEB may assume that the base setup has already been applied.
#   - ISO_SCRIPTS_DIR must match the path used when constructing the ISO;
#     the actual scripts are taken from ${SCRIPTS_DIR} (local) and copied to
#     the root of the ISO under this directory.
# -----------------------------------------------------------------------------