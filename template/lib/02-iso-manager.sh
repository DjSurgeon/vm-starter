#!/bin/bash
# =============================================================================
# template/lib/02-iso-manager.sh – OS ISO management
# =============================================================================

manage_iso() {
    if [ ! -f "${UBUNTU_ISO_PATH}" ]; then
        log "Downloading Ubuntu 24.04 Server ISO..."
        wget -q --show-progress -O "${UBUNTU_ISO_PATH}" "${UBUNTU_ISO_URL}"
    else
        success "Ubuntu ISO already exists: ${UBUNTU_ISO_FILENAME}"
    fi
}
