#!/bin/bash
# =============================================================================
# template/lib/04-provision-vm.sh – VirtualBox VM creation and configuration
# =============================================================================

provision_vm() {
    # Determine OS Type for VirtualBox
    TEMPLATE_OSTYPE="Ubuntu_64"

    log "Destroying old VM if exists for a clean slate..."
    VBoxManage controlvm "${TEMPLATE_NAME}" poweroff 2>/dev/null || true
    sleep 1
    VBoxManage unregistervm "${TEMPLATE_NAME}" --delete 2>/dev/null || true

    # CRITICAL: Also unregister the disk from VirtualBox media registry if it exists
    # VBoxManage closemedium will fail if the disk is still attached to a VM,
    # but unregistervm --delete should have handled it. This is a safety check.
    if VBoxManage list hdds | grep -q "${TEMPLATE_DISK_PATH}"; then
        log "Unregistering old medium from VirtualBox registry..."
        VBoxManage closemedium disk "${TEMPLATE_DISK_PATH}" --delete 2>/dev/null || true
    fi

    # Ensure physical directory is gone
    rm -rf "${DISK_IMAGES_DIR}/${TEMPLATE_NAME}"
    mkdir -p "${DISK_IMAGES_DIR}/${TEMPLATE_NAME}"

    log "Creating VirtualBox VM '${TEMPLATE_NAME}' (${TEMPLATE_OSTYPE})..."
    VBoxManage createvm --name "${TEMPLATE_NAME}" --ostype "${TEMPLATE_OSTYPE}" --register --basefolder "${DISK_IMAGES_DIR}"

    VBoxManage modifyvm "${TEMPLATE_NAME}" \
        --memory "${TEMPLATE_RAM_MB}" \
        --cpus "${TEMPLATE_CPU}" \
        --nic1 nat \
        --audio none \
        --usb off \
        --vrde off \
        --rtcuseutc on

    # Map SSH Port
    VBoxManage modifyvm "${TEMPLATE_NAME}" --natpf1 "guestssh,tcp,127.0.0.1,${SSH_PORT},,${SSH_VM_PORT}"

    # Create and attach Main Disk (SATA)
    log "Creating new virtual disk: ${TEMPLATE_DISK_PATH}"
    VBoxManage createmedium disk --filename "${TEMPLATE_DISK_PATH}" --size "${TEMPLATE_DISK_MB}" --format VDI
    VBoxManage storagectl "${TEMPLATE_NAME}" --name "${CONTROLLER_SATA}" --add sata --controller IntelAhci
    VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_SATA}" --port 0 --device 0 --type hdd --medium "${TEMPLATE_DISK_PATH}"

    # Create IDE controller for CD/DVDs
    VBoxManage storagectl "${TEMPLATE_NAME}" --name "${CONTROLLER_IDE}" --add ide
    VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 0 --device 0 --type dvddrive --medium "${ISO_PATH}"
    VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 1 --device 0 --type dvddrive --medium "${SEED_ISO}"

    # Set boot order
    VBoxManage modifyvm "${TEMPLATE_NAME}" --boot1 dvd --boot2 disk --boot3 none --boot4 none
}
