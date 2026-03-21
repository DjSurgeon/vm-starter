#!/bin/bash
# =============================================================================
# template/lib/05-install-os.sh – VM boot and GRUB automation
# =============================================================================

install_os() {
    log "Starting VM in headless mode..."
    VBoxManage startvm "${TEMPLATE_NAME}" --type headless

    log "Injecting 'autoinstall' kernel parameter into GRUB..."
    # Wait for VirtualBox to pass BIOS and show GRUB menu
    sleep 8 

    # 1. Press 'e' to edit the Ubuntu Server entry
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 12 92
    sleep 1

    # 2. Press 'Down' 3 times to reach the line starting with "linux"
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0

    # 3. Press 'End' to go to the end of the line
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 4f e0 cf

    # 4. Inject ' autoinstall' string
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputstring " autoinstall"
    sleep 1

    # 5. Press 'F10' to boot with the new parameter
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 44 c4

    log "Waiting for unattended installation to finish (5-10 minutes)..."
    log "The VM will power off automatically when done. Do NOT interrupt."

    # Progress spinner using global colors
    local spin_chars="/-\|"
    local spin_idx=0
    while true; do
        local state
        state=$(VBoxManage showvminfo "${TEMPLATE_NAME}" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"')
        if [ "$state" = "poweroff" ]; then
            printf "\r\033[K" # Clear spinner line
            break
        fi
        printf "\r${C_YELLOW}[%c] Installing Ubuntu Server... Please wait...${C_RESET}" "${spin_chars:$spin_idx:1}"
        spin_idx=$(( (spin_idx + 1) % 4 ))
        sleep 2
    done

    success "Installation completed. VM has powered off."
}
