#!/bin/bash
# =============================================================================
# template/lib/05-install-os.sh – VM boot and GRUB automation
# =============================================================================

install_os() {
    log "Starting VM in headless mode..."
    VBoxManage startvm "${TEMPLATE_NAME}" --type headless

    log "Injecting Ubuntu autoinstall parameters..."
    automate_ubuntu_grub

    # 2. Bucle de espera ROBUSTO
    while true; do
        local state
        state=$(VBoxManage showvminfo "${TEMPLATE_NAME}" --machinereadable 2>/dev/null | grep VMState= | cut -d= -f2 | tr -d '"')
        
        # SOLO salimos si el estado es explícitamente poweroff
        if [ "$state" = "poweroff" ]; then
            break
        fi
        
        # Si el estado es vacío, no salimos, simplemente esperamos al siguiente ciclo
        if [ -n "$state" ]; then
             printf "\r${C_YELLOW}[...] State: %s | Installing %s...${C_RESET}" "$state" "$SELECTED_DISTRO"
        fi
        
        sleep 10
    done

    printf "\n"
    success "Installation completed. VM has powered off."
}

automate_ubuntu_grub() {
    # Ubuntu usually takes some time to reach the GRUB menu
    sleep 8 
    # Press 'e' to edit the first entry
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 12 92 # 'e'
    sleep 1
    # Move down to the 'linux' line
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0 # Down
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0 # Down
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0 # Down
    # Go to end of line
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 4f e0 cf # End
    # Append autoinstall parameter
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputstring " autoinstall"
    sleep 1
    # Boot with F10
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 44 c4 # F10
}
