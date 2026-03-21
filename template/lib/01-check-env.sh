#!/bin/bash
# =============================================================================
# template/lib/01-check-env.sh – Dependency and environment checks
# =============================================================================

check_env() {
    local admin_user="${1:-$ADMIN_USER}"
    log "Using admin user: ${admin_user}"
    log "Checking required tools..."
    
    check_command VBoxManage "virtualbox"
    check_command genisoimage "genisoimage"
    check_command curl "curl"
    check_command wget "wget"

    # Ensure host SSH key exists to inject into VM
    HOST_PUB_KEY=""
    for key in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
        if [ -f "$key" ]; then
            HOST_PUB_KEY="$(cat "$key")"
            log "Found host SSH public key: $key"
            break
        fi
    done

    if [ -z "$HOST_PUB_KEY" ]; then
        log "No SSH key found on host. Generating a temporary ED25519 key..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q
        HOST_PUB_KEY="$(cat ~/.ssh/id_ed25519.pub)"
    fi
    
    # Export for other modules
    export HOST_PUB_KEY
    export ADMIN_USER="${admin_user}"
}
