#!/bin/bash
# =============================================================================
# scripts/create-template.sh – Build the base VM template (devpod-base)
# =============================================================================
# This script:
#   1. Loads the modular configuration (config/config.sh)
#   2. Checks required dependencies (VBoxManage, genisoimage, curl, wget)
#   3. Downloads Ubuntu 24.04 LTS Live Server ISO if not present
#   4. Generates Ubuntu autoinstall cloud-init files (user-data & meta-data)
#   5. Builds a seed ISO (cidata) containing the autoinstall config
#   6. Creates a VirtualBox VM with the template resources
#   7. Starts the VM for unattended installation and waits for poweroff
#   8. Ejects ISOs and marks as ready for cloning
# =============================================================================

set -e  # Exit immediately if any command fails

# -----------------------------------------------------------------------------
# 1. Load central configuration
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh" || { echo "❌ Error: Could not load config.sh"; exit 1; }

# -----------------------------------------------------------------------------
# 2. Helper functions
# -----------------------------------------------------------------------------
log() { echo -e "\e[1;34m[$(date +'%H:%M:%S')]\e[0m $*"; }
success() { echo -e "\e[1;32m[$(date +'%H:%M:%S')] ✅ $*\e[0m"; }
error() { echo -e "\e[1;31m[$(date +'%H:%M:%S')] ❌ ERROR: $*\e[0m" >&2; exit 1; }

check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Command '$1' not found. Please install it (e.g., sudo apt install $2) and try again."
    fi
}

# -----------------------------------------------------------------------------
# 3. Check dependencies & environment
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 4. Download Ubuntu ISO if not present
# -----------------------------------------------------------------------------
if [ ! -f "${UBUNTU_ISO_PATH}" ]; then
    log "Downloading Ubuntu 24.04 Server ISO..."
    wget -q --show-progress -O "${UBUNTU_ISO_PATH}" "${UBUNTU_ISO_URL}"
else
    success "Ubuntu ISO already exists: ${UBUNTU_ISO_FILENAME}"
fi

# -----------------------------------------------------------------------------
# 5. Generate Ubuntu Autoinstall (Cloud-init) files
# -----------------------------------------------------------------------------
log "Generating cloud-init autoinstall configuration..."

# Convertimos la variable PACKAGES_BASE (que tiene saltos de línea) en una 
# lista separada por comas limpia: "sudo,curl,wget,vim..."
# Limpiamos los comentarios (#...) antes de procesar la lista
PKG_LIST=$(echo "$PACKAGES_BASE" | sed 's/#.*//' | grep -v "openssh-server" | xargs | tr ' ' ',')
PKG_LIST="${PKG_LIST},docker.io,docker-compose-v2"

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
  
  # Usamos el formato de array en línea [pkg1, pkg2] para evitar TODO error de indentación YAML
  packages: [${PKG_LIST}]
  
  late-commands:
    # 1. Asegurar que el grupo docker existe antes de meter al usuario (|| true evita que falle)
    - curtin in-target -- sh -c "getent group docker || groupadd docker"
    - curtin in-target -- sh -c "usermod -aG docker ${ADMIN_USER} || true"
    
    # 2. Hardening de SSH tolerante a fallos
    - curtin in-target -- sh -c "sed -i 's/^#Port.*/Port ${SSH_VM_PORT}/' /etc/ssh/sshd_config || true"
    - curtin in-target -- sh -c "sed -i 's/^#PermitRootLogin.*/PermitRootLogin ${SSH_PERMIT_ROOT_LOGIN}/' /etc/ssh/sshd_config || true"
    - curtin in-target -- sh -c "sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication ${SSH_PASSWORD_AUTH}/' /etc/ssh/sshd_config || true"
    
    # 3. Creación de la Swap tolerante a fallos
    - curtin in-target -- sh -c "fallocate -l ${SWAP_SIZE_MB}M /swapfile || true"
    - curtin in-target -- sh -c "chmod 600 /swapfile || true"
    - curtin in-target -- sh -c "mkswap /swapfile || true"
    - curtin in-target -- sh -c "grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab || true"

# Pasamos configuración nativa de cloud-init para el PRIMER ARRANQUE
  user-data:
    runcmd:
      # Esto se ejecuta en el primer arranque, garantizando que el grupo docker no se borre
      - usermod -aG docker ${ADMIN_USER}

  shutdown: poweroff
EOF

cat > "${CLOUD_INIT_DIR}/meta-data" <<EOF
instance-id: ${TEMPLATE_NAME}
local-hostname: ${TEMPLATE_HOSTNAME}
EOF

# -----------------------------------------------------------------------------
# 6. Create Seed ISO (cidata)
# -----------------------------------------------------------------------------
SEED_ISO="${ISO_DIR}/seed-${TEMPLATE_NAME}.iso"
log "Building seed ISO with genisoimage..."
# Output must be labeled 'cidata' for Ubuntu installer to find it automatically
genisoimage -output "${SEED_ISO}" -volid cidata -joliet -rock -r "${CLOUD_INIT_DIR}/user-data" "${CLOUD_INIT_DIR}/meta-data" >/dev/null 2>&1

# -----------------------------------------------------------------------------
# 7. Create VirtualBox VM
# -----------------------------------------------------------------------------
log "Destroying old VM if exists for a clean slate..."
VBoxManage controlvm "${TEMPLATE_NAME}" poweroff 2>/dev/null || true
sleep 2
VBoxManage unregistervm "${TEMPLATE_NAME}" --delete 2>/dev/null || true

rm -rf "${DISK_IMAGES_DIR}/${TEMPLATE_NAME}"

log "Creating VirtualBox VM '${TEMPLATE_NAME}'..."
VBoxManage createvm --name "${TEMPLATE_NAME}" --ostype "${TEMPLATE_OSTYPE}" --register --basefolder "${DISK_IMAGES_DIR}"

VBoxManage modifyvm "${TEMPLATE_NAME}" \
    --memory "${TEMPLATE_RAM_MB}" \
    --cpus "${TEMPLATE_CPU}" \
    --nic1 nat \
    --audio none \
    --usb off \
    --vrde off \
    --rtcuseutc on

# Map SSH Port (Base Template mapping, clones will override this)
VBoxManage modifyvm "${TEMPLATE_NAME}" --natpf1 "guestssh,tcp,127.0.0.1,${SSH_PORT},,${SSH_VM_PORT}"

# Create and attach Main Disk (SATA)
VBoxManage createmedium disk --filename "${TEMPLATE_DISK_PATH}" --size "${TEMPLATE_DISK_MB}" --format VDI
VBoxManage storagectl "${TEMPLATE_NAME}" --name "${CONTROLLER_SATA}" --add sata --controller IntelAhci
VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_SATA}" --port 0 --device 0 --type hdd --medium "${TEMPLATE_DISK_PATH}"

# Create IDE controller for CD/DVDs (better compatibility for booting ISOs than SATA)
VBoxManage storagectl "${TEMPLATE_NAME}" --name "${CONTROLLER_IDE}" --add ide
VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 0 --device 0 --type dvddrive --medium "${UBUNTU_ISO_PATH}"
VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 1 --device 0 --type dvddrive --medium "${SEED_ISO}"

# Set boot order
VBoxManage modifyvm "${TEMPLATE_NAME}" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# -----------------------------------------------------------------------------
# 8. Start VM and inject 'autoinstall' via GRUB
# -----------------------------------------------------------------------------
log "Starting VM in headless mode..."
VBoxManage startvm "${TEMPLATE_NAME}" --type headless

log "Injecting 'autoinstall' kernel parameter into GRUB..."
# Esperamos unos segundos a que VirtualBox pase la BIOS y muestre el menú GRUB
sleep 8 

# 1. Pulsamos 'e' para editar la entrada de Ubuntu Server
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 12 92
sleep 1

# 2. Pulsamos 'Abajo' 3 veces para llegar a la línea que empieza por "linux"
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 50 e0 d0

# 3. Pulsamos 'Fin' para ir al final de la línea
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode e0 4f e0 cf

# 4. Inyectamos la palabra ' autoinstall' limpiamente
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputstring " autoinstall"
sleep 1

# 5. Pulsamos 'F10' para arrancar con el nuevo parámetro
VBoxManage controlvm "${TEMPLATE_NAME}" keyboardputscancode 44 c4

log "Waiting for unattended installation to finish (5-10 minutes)..."
log "The VM will power off automatically when done. Do NOT interrupt."

# El spinner limpio. Ya no machacamos el teclado.
spin_chars="/-\|"
spin_idx=0
while true; do
    STATE=$(VBoxManage showvminfo "${TEMPLATE_NAME}" --machinereadable | grep VMState= | cut -d= -f2 | tr -d '"')
    if [ "$STATE" = "poweroff" ]; then
        echo "" # Limpiar la línea del spinner
        break
    fi
    printf "\r\e[1;33m[%c] Installing Ubuntu Server... Please wait...\e[0m" "${spin_chars:$spin_idx:1}"
    spin_idx=$(( (spin_idx + 1) % 4 ))
    sleep 2
done

success "Installation completed. VM has powered off."

# -----------------------------------------------------------------------------
# 9. Cleanup & Eject ISOs
# -----------------------------------------------------------------------------
log "Ejecting installation media..."
VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 0 --device 0 --medium none
VBoxManage storageattach "${TEMPLATE_NAME}" --storagectl "${CONTROLLER_IDE}" --port 1 --device 0 --medium none

# Force boot from disk from now on
VBoxManage modifyvm "${TEMPLATE_NAME}" --boot1 disk --boot2 none

# Remove seed ISO
rm -f "${SEED_ISO}"

# Mark as template
VBoxManage modifyvm "${TEMPLATE_NAME}" --description "DevPod Base Template [Ubuntu 24.04 | Docker] - DO NOT START DIRECTLY"

echo "======================================================================="
success "DevPod Base Template '${TEMPLATE_NAME}' created successfully!"
echo "======================================================================="
log "Next steps: You can now clone this template using your clone scripts."