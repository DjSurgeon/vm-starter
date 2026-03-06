#!/bin/bash
# =============================================================================
# DevPod Configuration – 01-locale.sh
# Purpose: Define localization settings (language, keyboard, timezone).
# =============================================================================

# -----------------------------------------------------------------------------
# Locale settings – used during OS installation and system configuration.
# -----------------------------------------------------------------------------
export LOCALE="en_US.UTF-8"					# System language and encoding
export KEYBOARD_LAYOUT="es"					# Keyboard layout (e.g., es, us, fr)
export TIMEZONE="Europe/Madrid"				# Timezone for the VM

# -----------------------------------------------------------------------------
# These variables are typically consumed by:
#   - cloud-init user-data (locale, timezone)
#   - preseed files (if used)
#   - post-install scripts (to set localectl, timedatectl)
# -----------------------------------------------------------------------------