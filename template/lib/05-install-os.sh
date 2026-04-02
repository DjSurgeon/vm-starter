#!/bin/bash
# =============================================================================
# template/lib/05-install-os.sh – VM boot and GRUB automation
# =============================================================================

install_os() {
    # 1. Aseguramos que el servidor escuche en todas las interfaces (0.0.0.0)
    log "Starting temporary HTTP server for Debian preseed..."
    # Usamos un puerto menos común para evitar conflictos
    cd "${CLOUD_INIT_DIR}" && python3 -m http.server 8080 > /dev/null 2>&1 &
    HTTP_PID=$!
    
    # Damos un segundo para que el servidor levante
    sleep 2

    log "Starting VM in headless mode..."
    VBoxManage startvm "${TEMPLATE_NAME}" --type headless

    if [ "$SELECTED_DISTRO" = "debian" ]; then
        log "Injecting Debian preseed via HTTP..."
        automate_debian_boot
    else
        log "Injecting Ubuntu autoinstall parameters..."
        automate_ubuntu_grub
    fi

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

    kill $HTTP_PID
    printf "\n"
    success "Installation completed. VM has powered off."
}

automate_debian_boot() {
    sleep 12 # Tiempo para que cargue el menú de Debian

    # 1. Presionamos ESC para llegar al prompt 'boot:'
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 01 81
    sleep 2

    # 2. Comando de boot apuntando a nuestro servidor local (Host)
    # Cambiamos file:///media/ por http://10.0.2.2:8080/
    local boot_cmd="auto url=http://10.0.2.2:8080/preseed.cfg priority=critical locale=${LOCALE} keymap=${KEYBOARD_LAYOUT} interface=auto"
    
    log "Typing boot command: $boot_cmd"
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputstring "$boot_cmd"
    sleep 2

    # 3. ENTER para arrancar
    VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 1c 9c
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
