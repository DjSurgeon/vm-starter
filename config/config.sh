#!/bin/bash
# =============================================================================
# DevPod Configuration Loader
# =============================================================================
# Loads all modular configuration files in numerical order.
# Usage: source config/config.sh
# =============================================================================

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable debug output (set to true to see which files are loaded)
DEBUG_LOAD=${DEBUG_LOAD:-false}

# Load all numbered modules in order (00-*.sh, 01-*.sh, ...)
for config_file in $(ls "$CONFIG_DIR"/[0-9][0-9]-*.sh 2>/dev/null | sort); do
    if [ -f "$config_file" ]; then
        if [ "$DEBUG_LOAD" = true ]; then
            echo "Loading config: $(basename "$config_file")"
        fi
        # shellcheck source=/dev/null
        source "$config_file"
    fi
done

# Load utility functions last (they may depend on all previous variables)
if [ -f "$CONFIG_DIR/99-functions.sh" ]; then
    if [ "$DEBUG_LOAD" = true ]; then
        echo "Loading config: 99-functions.sh"
    fi
    source "$CONFIG_DIR/99-functions.sh"
else
    echo "Warning: 99-functions.sh not found. Some features may not work." >&2
fi

# Optional: Verify that configuration loaded correctly
if command -v devpod_config_loaded &> /dev/null; then
    devpod_config_loaded
else
    echo "Warning: devpod_config_loaded function not defined. Check your modules." >&2
fi