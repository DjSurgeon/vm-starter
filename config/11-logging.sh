#!/bin/bash
# =============================================================================
# DevPod Configuration – 11-logging.sh
# Purpose: Define logging behavior and terminal output preferences.
# Source order: Must be sourced after 00-init.sh (uses LOGS_DIR).
# =============================================================================

# -----------------------------------------------------------------------------
# Logging verbosity level.
# Possible values: DEBUG, INFO, WARN, ERROR
# - DEBUG: Most detailed output (useful for troubleshooting)
# - INFO: Normal operational messages (default)
# - WARN: Only warnings and errors
# - ERROR: Only error messages
# -----------------------------------------------------------------------------
export LOG_LEVEL="INFO"

# -----------------------------------------------------------------------------
# Path to the main log file where all DevPod scripts write their output.
# LOGS_DIR is defined in 00-init.sh and points to ${BASE_DIR}/logs.
# The directory is automatically created if it does not exist.
# -----------------------------------------------------------------------------
export LOG_FILE="${LOGS_DIR}/devpod.log"

# -----------------------------------------------------------------------------
# Enable or disable colored output in terminal messages.
# When true, log messages use ANSI color codes for better readability.
# Set to false if your terminal does not support colors or you prefer plain text.
# -----------------------------------------------------------------------------
export USE_COLORS="true"

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - LOG_LEVEL controls which messages are printed to stdout/stderr.
#     Scripts should respect this variable (e.g., using `log_debug`, `log_info`).
#   - LOG_FILE is used by logging functions to append timestamps and messages.
#   - USE_COLORS affects the `log` family of functions; if false, color codes
#     are stripped or omitted.
#   - All scripts should source this file (indirectly via config.sh) to access
#     these settings.
# -----------------------------------------------------------------------------	