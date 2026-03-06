#!/bin/bash
# =============================================================================
# DevPod Configuration – 06-network.sh
# Purpose: Define network settings, port forwarding, and SSH hardening.
# =============================================================================

# -----------------------------------------------------------------------------
# SSH port mapping (host → VM)
# -----------------------------------------------------------------------------
export SSH_PORT="4222"				# Port on the host that forwards to VM's SSH
export SSH_VM_PORT="22"				# Standard SSH port inside the VM

# -----------------------------------------------------------------------------
# Additional port forwards for web development (host → VM)
# -----------------------------------------------------------------------------
export HTTP_HOST_PORT="8080"		# Host port for HTTP (maps to VM port 80)
export HTTPS_HOST_PORT="8443"		# Host port for HTTPS (maps to VM port 443)

# -----------------------------------------------------------------------------
# Range of host ports for multiple clones (each gets a unique SSH port)
# -----------------------------------------------------------------------------
export SSH_PORT_RANGE_START="4222"	# First port in the range (inclusive)
export SSH_PORT_RANGE_END="4299"	# Last port in the range (inclusive)

# -----------------------------------------------------------------------------
# SSH daemon hardening (applied inside the VM)
# -----------------------------------------------------------------------------
export SSH_PERMIT_ROOT_LOGIN="no"	# Disable direct root login via SSH
export SSH_PASSWORD_AUTH="no"		# Disable password authentication (use SSH keys only)

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - SSH_PORT is used when creating port forwarding rules in VirtualBox.
#   - For cloned projects, each VM gets a unique SSH port from the range.
#   - SSH_VM_PORT is the internal port where sshd listens (usually 22).
#   - HTTP_HOST_PORT and HTTPS_HOST_PORT are for development servers (e.g., Vite, Node).
#   - SSH hardening settings are applied via cloud-init or post-install scripts.
# -----------------------------------------------------------------------------