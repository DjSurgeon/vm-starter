#!/bin/bash
# =============================================================================
# DevPod Configuration – 12-behavior.sh
# Purpose: Define automatic behavior settings for VM creation and connection.
# Source order: Should be sourced after 00-init.sh (no direct dependencies).
# =============================================================================

# -----------------------------------------------------------------------------
# Automatically start the VM after cloning?
# If true, the clone script will power on the newly created VM.
# If false, the VM is left powered off (you must start it manually).
# -----------------------------------------------------------------------------
export AUTO_START_CLONE="true"

# -----------------------------------------------------------------------------
# Wait for SSH to become available after starting the VM?
# When true, the clone script will repeatedly test the SSH connection until
# it succeeds or the timeout (SSH_WAIT_TIMEOUT) is reached.
# -----------------------------------------------------------------------------
export WAIT_FOR_SSH="true"

# -----------------------------------------------------------------------------
# Maximum time (in seconds) to wait for SSH to become responsive.
# This is only relevant when WAIT_FOR_SSH="true". After this timeout,
# the script may give up and report an error, but the VM will continue running.
# -----------------------------------------------------------------------------
export SSH_WAIT_TIMEOUT="120"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - These settings are primarily used by the project clone script
#     (projects/clone.sh) to control post‑creation behavior.
#   - AUTO_START_CLONE="true" saves a manual step, but you may want to disable
#     it if you need to adjust VM settings before first boot.
#   - WAIT_FOR_SSH ensures that subsequent provisioning steps (like running
#     type‑specific setup scripts) can be executed immediately after cloning.
#   - SSH_WAIT_TIMEOUT should be long enough for the VM to boot and start sshd,
#     especially on slower hosts (120 seconds is usually safe).
# -----------------------------------------------------------------------------	