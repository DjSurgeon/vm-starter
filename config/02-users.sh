#!/bin/bash
# =============================================================================
# DevPod Configuration – 02-users.sh
# Purpose: Define user accounts and passwords.
# =============================================================================

# -----------------------------------------------------------------------------
# Administrative user (non‑root) for daily development work.
# -----------------------------------------------------------------------------
export ADMIN_USER="${ADMIN_USER:-dev}"                     # Username for the main developer account
export ADMIN_FULLNAME="Developer"           # Full name (GECOS field)
export ADMIN_PASSWORD="tempuser123"         # Initial password – CHANGE AFTER FIRST BOOT!

# -----------------------------------------------------------------------------
# Root account – kept for emergency/system administration.
# -----------------------------------------------------------------------------
export ROOT_PASSWORD="temproot123"          # Initial root password – CHANGE AFTER FIRST BOOT!

# -----------------------------------------------------------------------------
# These variables are used by:
#   - cloud‑init user-data (creates the user, sets password, adds SSH keys)
#   - post‑install scripts (for ownership, group membership, sudoers)
#   - clone scripts (to inject the same user into cloned VMs)
# -----------------------------------------------------------------------------