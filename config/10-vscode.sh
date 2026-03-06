#!/bin/bash
# =============================================================================
# DevPod Configuration – 10-vscode.sh
# Purpose: Optimize VS Code Remote SSH connections and SSH keepalive settings.
# Source order: Should be sourced after 00-init.sh (no direct dependencies).
# =============================================================================

# -----------------------------------------------------------------------------
# VS Code Remote SSH client settings (applied to host's VS Code configuration)
# These options prevent the connection from dropping after ~15 minutes of idle
# due to VirtualBox NAT timeouts (see doc/SSH_VSCODE_FIX.md).
# -----------------------------------------------------------------------------

# Disable VS Code's "local server" mode – forces each window to use a direct
# SSH connection instead of a shared SOCKS proxy. This avoids the NAT timeout
# issue because there is no persistent tunnel that can go stale.
export VSCODE_USE_LOCAL_SERVER="false"

# Disable dynamic forwarding (–D flag) – removes the SOCKS proxy entirely.
# Without this, VS Code may still attempt to use forwarding even when the
# local server is disabled.
export VSCODE_ENABLE_DYNAMIC_FORWARDING="false"

# Increase the connection timeout to allow slower VM boots or network delays.
export VSCODE_CONNECT_TIMEOUT="60"          # Timeout in seconds

# -----------------------------------------------------------------------------
# SSH keepalive settings (applied both on the host and inside the VM)
# These keep the TCP connection alive even when no data is being transferred,
# preventing NAT timeouts from dropping idle connections.
# -----------------------------------------------------------------------------

# Interval (in seconds) between keepalive messages sent from the client.
export SSH_KEEPALIVE_INTERVAL="60"

# Maximum number of missed keepalive replies before the connection is terminated.
export SSH_KEEPALIVE_COUNTMAX="3"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - The VS Code settings are applied to the host's VS Code configuration
#     (settings.json) by the host‑config/vscode‑settings.sh script.
#   - The SSH keepalive settings are written to /etc/ssh/ssh_config (client)
#     and /etc/ssh/sshd_config (server) inside the VM via cloud‑init or
#     post‑install scripts.
#   - These values are essential for a stable Remote SSH experience with
#     VirtualBox NAT networking. Without them, the connection may drop after
#     10‑15 minutes of inactivity.
# -----------------------------------------------------------------------------