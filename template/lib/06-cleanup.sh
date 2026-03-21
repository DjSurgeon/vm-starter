#!/bin/bash
# =============================================================================
# template/lib/06-cleanup.sh – Post-install cleanup and template marking
# =============================================================================

finalize_template() {
    log "Ejecting installation media..."
    VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 0 --device 0 --medium none
    VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 1 --device 0 --medium none

    # Force boot from disk from now on
    VBoxManage modifyvm "${TEMPLATE_NAME}" --boot1 disk --boot2 none

    # Remove seed ISO
    [ -f "${SEED_ISO}" ] && rm -f "${SEED_ISO}"

    # Mark as template
    VBoxManage modifyvm "${TEMPLATE_NAME}" --description "DevPod Base Template [Ubuntu 24.04 | Docker] - DO NOT START DIRECTLY"

    echo "======================================================================="
    success "DevPod Base Template '${TEMPLATE_NAME}' created successfully!"
    echo "======================================================================="
    log "Next steps: You can now clone this template using your clone scripts."
}
