#!/bin/bash
# =============================================================================
# DevPod Configuration – 11-logging.sh
# Purpose: Define logging behavior and terminal output preferences.
# =============================================================================

# -----------------------------------------------------------------------------
# Logging verbosity level. (DEBUG, INFO, WARN, ERROR)
# -----------------------------------------------------------------------------
export LOG_LEVEL="INFO"
export LOG_FILE="${LOGS_DIR}/devpod.log"
export USE_COLORS="true"

# -----------------------------------------------------------------------------
# ANSI Color Codes (only if USE_COLORS is true)
# -----------------------------------------------------------------------------
if [ "$USE_COLORS" = "true" ]; then
    export C_RESET="\e[0m"
    export C_BOLD="\e[1m"
    export C_RED="\e[1;31m"
    export C_GREEN="\e[1;32m"
    export C_YELLOW="\e[1;33m"
    export C_BLUE="\e[1;34m"
    export C_MAGENTA="\e[1;35m"
    export C_CYAN="\e[1;36m"
else
    export C_RESET=""
    export C_BOLD=""
    export C_RED=""
    export C_GREEN=""
    export C_YELLOW=""
    export C_BLUE=""
    export C_MAGENTA=""
    export C_CYAN=""
fi
