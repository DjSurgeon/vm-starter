#!/bin/bash
# =============================================================================
# DevPod Configuration – 07-packages.sh
# Purpose: Define lists of system packages to be installed.
# Source order: Should be sourced after 00-init.sh (no direct dependencies).
# =============================================================================

# -----------------------------------------------------------------------------
# Base system packages – essential tools for any development VM.
# These are installed via apt during the initial setup.
# -----------------------------------------------------------------------------
export PACKAGES_BASE="
	openssh-server				# SSH daemon for remote access
	sudo						# Superuser privileges for regular users
	curl						# Command-line tool for transferring data with URLs
	wget						# Alternative downloader
	vim							# Terminal text editor
	nano						# Simple terminal text editor
	git							# Version control system
	htop						# Interactive process viewer
	build-essential				# Compilers and libraries (gcc, make, etc.)
	python3						# Python 3 interpreter
	python3-pip					# Python package installer
	python3-venv				# Python virtual environment module
	ca-certificates				# CA certificates for SSL/TLS
	gnupg						# GNU Privacy Guard (for key management)
	apt-transport-https			# Allow apt to use HTTPS repositories
	software-properties-common	# Manage repositories (add-apt-repository)
"

# -----------------------------------------------------------------------------
# Docker packages – installed from Docker's official repository.
# -----------------------------------------------------------------------------
export PACKAGES_DOCKER="
	docker-ce					# Docker Community Edition engine
	docker-ce-cli				# Docker command-line interface
	containerd.io				# Container runtime (used by Docker)
	docker-compose-plugin		# Docker Compose V2 plugin (runs as docker compose)
"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - These variables are consumed by cloud-init (user-data) or by provisioning
#     scripts (e.g., setup-base.sh) to install the listed packages.
#   - The lists are space‑separated (each entry on a new line for readability).
#   - Docker packages are kept separate because they require adding a third‑party
#     repository before installation.
#   - Additional packages for specific project types (web, mobile) are installed
#     via type‑specific scripts (e.g., setup-web.sh) and are NOT listed here.
# -----------------------------------------------------------------------------