#!/bin/bash
# =============================================================================
# template/lib/03-cloud-init.sh – Provisioning config generation (Ubuntu/Debian)
# =============================================================================

generate_cloud_init() {
    if [ "$SELECTED_DISTRO" = "debian" ]; then
        log "Generating Debian preseed configuration..."
        generate_debian_preseed
    else
        log "Generating Ubuntu cloud-init autoinstall configuration..."
        generate_ubuntu_autoinstall
    fi

    # 3. Build Seed ISO
    # For Ubuntu it needs to be labeled 'cidata'
    # For Debian, we'll just put it in the root of the same ISO or use a label
    export SEED_ISO="${ISO_DIR}/seed-${TEMPLATE_NAME}.iso"
    log "Building seed ISO with genisoimage..."
    
    if [ "$SELECTED_DISTRO" = "debian" ]; then
        # Ensure preseed.cfg is at the root of the ISO by using a temporary directory
        local debian_seed_dir="${CLOUD_INIT_DIR}/debian_seed"
        mkdir -p "${debian_seed_dir}"
        cp "${CLOUD_INIT_DIR}/preseed.cfg" "${debian_seed_dir}/preseed.cfg"
        # OEMDRV is a magic label that Debian Installer looks for to mount media
        genisoimage -output "${SEED_ISO}" -volid "OEMDRV" -r \
            "${debian_seed_dir}" >/dev/null 2>&1
    else
        genisoimage -output "${SEED_ISO}" -volid cidata -joliet -rock -r \
            "${CLOUD_INIT_DIR}/user-data" "${CLOUD_INIT_DIR}/meta-data" >/dev/null 2>&1
    fi
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
    password: "$(openssl passwd -6 ${ADMIN_PASSWORD})"
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

generate_debian_preseed() {
    # Basic Debian Preseed - Minimal Ubuntu-like configuration
    cat > "${CLOUD_INIT_DIR}/preseed.cfg" <<'EOF'
### Localization
d-i debian-installer/locale string ${LOCALE}
d-i keyboard-configuration/xkb-keymap select ${KEYBOARD_LAYOUT}

### Network Configuration
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ${TEMPLATE_HOSTNAME}
d-i netcfg/get_domain string unassigned-domain

### Mirror Settings
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

### Account Setup
d-i passwd/root-login boolean false
d-i passwd/user-fullname string ${ADMIN_FULLNAME}
d-i passwd/username string ${ADMIN_USER}
d-i passwd/user-password password ${ADMIN_PASSWORD}
d-i passwd/user-password-again password ${ADMIN_PASSWORD}
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

### Clock and Time Zone
d-i clock-setup/utc boolean true
d-i time/zone string ${TIMEZONE}

### Partitioning (Simplified - No LVM/Crypto)
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

### Base system installation
d-i base-installer/install-recommends boolean false

### APT setup
d-i apt-setup/non-free-firmware boolean true
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true
d-i apt-setup/use_mirror boolean true

### Software Selection
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string sudo curl wget git vim nano ca-certificates gnupg apt-transport-https build-essential docker.io docker-compose
d-i pkgsel/upgrade select safe-upgrade

### Bootloader Installation
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

### Finish Installation
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean true

### Late Command
d-i preseed/late_command string \
    in-target /bin/bash -c "echo '${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${ADMIN_USER} && chmod 440 /etc/sudoers.d/${ADMIN_USER}"; \
    in-target /bin/bash -c "usermod -aG docker ${ADMIN_USER}"; \
    in-target /bin/bash -c "sed -i 's/^#*Port .*/Port ${SSH_VM_PORT}/' /etc/ssh/sshd_config"; \
    in-target /bin/bash -c "systemctl enable ssh"
EOF
}
