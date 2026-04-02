#!/bin/bash
# =============================================================================
# template/lib/02-iso-manager.sh – OS ISO management
# =============================================================================

manage_iso() {
    if [ -z "$ISO_URL" ]; then
        error "No ISO URL defined for distro: ${SELECTED_DISTRO}"
    fi

    if [ ! -f "${ISO_PATH}" ]; then
        log "Downloading ${SELECTED_DISTRO} ISO..."
        wget -q --show-progress -O "${ISO_PATH}" "${ISO_URL}"
    else
        success "ISO already exists: ${ISO_FILENAME}"
    fi
}
