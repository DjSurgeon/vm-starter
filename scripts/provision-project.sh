#!/bin/bash
# =============================================================================
# scripts/provision-project.sh – Configure project-specific tools in the VM
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/config/config.sh" || { echo "❌ Error: Could not load config.sh"; exit 1; }

VM_NAME="$1"
PROJECT_TYPE="$2"

if [ -z "$VM_NAME" ] || [ -z "$PROJECT_TYPE" ]; then
    error "Usage: $0 <vm_name> <type>"
fi

log "Provisioning '$VM_NAME' as a '$PROJECT_TYPE' project..."

# Update the hostname inside the VM to match the clone's name
log "Updating hostname to '$VM_NAME'..."
ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$VM_NAME" "$ADMIN_PASSWORD" <<'EOF'
    REMOTE_VM_NAME="$1"
    REMOTE_ADMIN_PASSWORD="$2"
    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S hostnamectl set-hostname "$REMOTE_VM_NAME"
    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sed -i "s/127.0.1.1.*/127.0.1.1\t$REMOTE_VM_NAME/g" /etc/hosts
EOF

# Disable noisy default Ubuntu MOTD and configure 42-style dynamic MOTD
log "Configuring 42-style dynamic MOTD..."
ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_PASSWORD" "$ADMIN_USER" <<'EOF'
    REMOTE_ADMIN_PASSWORD="$1"
    REMOTE_ADMIN_USER="$2"
    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/50-ubuntu-adv 2>/dev/null || true

    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sh -c "cat << EOF_MOTD > /etc/update-motd.d/99-devpod
#!/bin/bash
CORES=\$(nproc)
RAM=\$(free -m | awk '/^Mem:/ {print \$2}')
DISK=\$(df -h / | awk 'NR==2 {print \$4}')
HOST=\$(hostname)

echo \"\"
printf \"/* ************************************************************************** */\n\"
printf \"/*                                                                            */\n\"
printf \"/*                                                        :::      ::::::::   */\n\"
printf \"/*   %-51s:+:      :+:    :+:   */\n\" \"INCEPTION DEV ENVIRONMENT\"
printf \"/*   %-49s+:+ +:+         +:+     */\n\" \"\"
printf \"/*   %-47s+#+  +:+       +#+        */\n\" \"Hostname: \$HOST\"
printf \"/*   %-45s+#+#+#+#+#+   +#+           */\n\" \"Resources: \$CORES Cores | \${RAM}MB RAM | \$DISK Free\"
printf \"/*   %-50s#+#    #+#             */\n\" \"Sudo Pass: ${REMOTE_ADMIN_PASSWORD}\"
printf \"/*   %-49s###   ########.fr       */\n\" \"Data Dir: /home/${REMOTE_ADMIN_USER}/data\"
printf \"/*                                                                            */\n\"
printf \"/* ************************************************************************** */\n\"
echo \"\"
EOF_MOTD"

    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chmod +x /etc/update-motd.d/99-devpod
EOF

# Run the provisioning commands via SSH
if [ "$PROJECT_TYPE" = "web" ]; then
    log "Installing Node.js ${DEV_NODE_VERSION} and pnpm ${DEV_PNPM_VERSION}..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_PASSWORD" "$DEV_NODE_VERSION" "$DEV_PNPM_VERSION" <<'EOF'
        REMOTE_ADMIN_PASSWORD="$1"
        REMOTE_NODE_VERSION="$2"
        REMOTE_PNPM_VERSION="$3"
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq
        curl -fsSL "https://deb.nodesource.com/setup_${REMOTE_NODE_VERSION}.x" -o nodesource_setup.sh
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -E bash nodesource_setup.sh >/dev/null 2>&1
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs >/dev/null 2>&1
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S npm install -g "pnpm@${REMOTE_PNPM_VERSION}" >/dev/null 2>&1
        rm -f nodesource_setup.sh
        mkdir -p ~/projects
EOF

elif [ "$PROJECT_TYPE" = "inception" ]; then
    log "Running clean provisioning for Inception..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_USER" "$ADMIN_PASSWORD" "$INCEPTION_DOMAIN" <<'EOF'
        REMOTE_ADMIN_USER="$1"
        REMOTE_ADMIN_PASSWORD="$2"
        REMOTE_INCEPTION_DOMAIN="$3"

        echo "===================================================="
        echo "  Aprovisionamiento Limpio de Inception para: ${REMOTE_ADMIN_USER}"
        echo "===================================================="

        # 1. Configuración Real del archivo /etc/hosts
        echo "Fixing /etc/hosts inside the VM..."
        if ! grep -q "${REMOTE_INCEPTION_DOMAIN}" /etc/hosts; then
            echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sh -c "echo '127.0.0.1    ${REMOTE_INCEPTION_DOMAIN}' >> /etc/hosts" > /dev/null
            echo "[OK] Dominio ${REMOTE_INCEPTION_DOMAIN} enlazado a 127.0.0.1"
        fi

        # 2. Estructura de Persistencia en el Host
        echo "Creating physical volume paths on the host..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${REMOTE_ADMIN_USER}/data/mariadb"
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${REMOTE_ADMIN_USER}/data/wordpress"
        
        # Asegurar permisos
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chown -R "${REMOTE_ADMIN_USER}:${REMOTE_ADMIN_USER}" "/home/${REMOTE_ADMIN_USER}/data" 2>/dev/null || true
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chmod -R 755 "/home/${REMOTE_ADMIN_USER}/data"
        echo "[OK] Carpetas de datos creadas en /home/${REMOTE_ADMIN_USER}/data"

        # 3. Limpieza de entorno
        rm -rf "/home/${REMOTE_ADMIN_USER}/inception"

        echo "===================================================="
        echo "  ¡VM lista! Entra, clona tu repo en tu HOME y ejecuta make"
        echo "===================================================="
EOF
fi

success "Provisioning for '$VM_NAME' complete."
