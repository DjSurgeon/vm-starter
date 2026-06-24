#!/bin/bash
# =============================================================================
# template/lib/03-cloud-init.sh – Provisioning config generation (Ubuntu)
# =============================================================================

generate_cloud_init() {
    log "Generating Ubuntu cloud-init autoinstall configuration..."
    generate_ubuntu_autoinstall

    # 3. Build Seed ISO
    # For Ubuntu it needs to be labeled 'cidata'
    export SEED_ISO="${ISO_DIR}/seed-${TEMPLATE_NAME}.iso"
    log "Building seed ISO with genisoimage..."
    
    genisoimage -output "${SEED_ISO}" -volid cidata -joliet -rock -r \
        "${CLOUD_INIT_DIR}/user-data" "${CLOUD_INIT_DIR}/meta-data" >/dev/null 2>&1
}

generate_ubuntu_autoinstall() {
    # Clean and format package list from PACKAGES_BASE
    local pkg_list
    pkg_list=$(echo "$PACKAGES_BASE" | sed 's/#.*//' | grep -v "openssh-server" | xargs | tr ' ' ',')
    pkg_list="${pkg_list},docker.io,docker-compose-v2"

    cat > "${CLOUD_INIT_DIR}/user-data" <<EOF
#cloud-config
autoinstall:
  version: 1
  locale: ${LOCALE}
  timezone: ${TIMEZONE}
  keyboard:
    layout: ${KEYBOARD_LAYOUT}
  
  network:
    network:
      version: 2
      ethernets:
        enp0s3:
          dhcp4: true
  
  identity:
    hostname: ${TEMPLATE_HOSTNAME}
    password: "$(openssl passwd -6 "${ADMIN_PASSWORD}")"
    username: ${ADMIN_USER}
  
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - "${HOST_PUB_KEY}"
  
  storage:
    layout:
      name: direct
  
  packages: [${pkg_list}]
  
  late-commands:
    - curtin in-target -- sh -c "getent group docker || groupadd docker"
    - curtin in-target -- sh -c "usermod -aG docker ${ADMIN_USER} || true"
    - curtin in-target -- sh -c "sed -i 's/^#Port.*/Port ${SSH_VM_PORT}/' /etc/ssh/sshd_config || true"
    - curtin in-target -- sh -c "sed -i 's/^#PermitRootLogin.*/PermitRootLogin ${SSH_PERMIT_ROOT_LOGIN}/' /etc/ssh/sshd_config || true"
    - curtin in-target -- sh -c "sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication ${SSH_PASSWORD_AUTH}/' /etc/ssh/sshd_config || true"
    - curtin in-target -- sh -c "fallocate -l ${SWAP_SIZE_MB}M /swapfile || true"
    - curtin in-target -- sh -c "chmod 600 /swapfile || true"
    - curtin in-target -- sh -c "mkswap /swapfile || true"
    - curtin in-target -- sh -c "grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab || true"

  user-data:
    package_upgrade: true
    runcmd:
      - usermod -aG docker ${ADMIN_USER}

  shutdown: poweroff
EOF

    cat > "${CLOUD_INIT_DIR}/meta-data" <<EOF
instance-id: ${TEMPLATE_NAME}
local-hostname: ${TEMPLATE_HOSTNAME}
EOF
}
