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

# Run the provisioning commands via SSH
if [ "$PROJECT_TYPE" = "web" ]; then
    log "Installing Node.js ${DEV_NODE_VERSION} and pnpm ${DEV_PNPM_VERSION}..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" <<EOF
        echo "${ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq
        curl -fsSL https://deb.nodesource.com/setup_${DEV_NODE_VERSION}.x -o nodesource_setup.sh
        echo "${ADMIN_PASSWORD}" | sudo -S -E bash nodesource_setup.sh >/dev/null 2>&1
        echo "${ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs >/dev/null 2>&1
        echo "${ADMIN_PASSWORD}" | sudo -S npm install -g pnpm@${DEV_PNPM_VERSION} >/dev/null 2>&1
        rm -f nodesource_setup.sh
        mkdir -p ~/projects
EOF

elif [ "$PROJECT_TYPE" = "inception" ]; then
    log "Running clean provisioning for Inception..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" <<EOF
        echo "===================================================="
        echo "  Aprovisionamiento Limpio de Inception para: ${ADMIN_USER}"
        echo "===================================================="

        # 1. Configuración Real del archivo /etc/hosts
        echo "Fixing /etc/hosts inside the VM..."
        if ! grep -q "${INCEPTION_DOMAIN}" /etc/hosts; then
            echo "${ADMIN_PASSWORD}" | sudo -S sh -c 'echo "127.0.0.1    ${INCEPTION_DOMAIN}" >> /etc/hosts' > /dev/null
            echo "[OK] Dominio ${INCEPTION_DOMAIN} enlazado a 127.0.0.1"
        fi

        # 2. Estructura de Persistencia en el Host
        echo "Creating physical volume paths on the host..."
        echo "${ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${ADMIN_USER}/data/mariadb"
        echo "${ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${ADMIN_USER}/data/wordpress"
        
        # Asegurar permisos
        echo "${ADMIN_PASSWORD}" | sudo -S chown -R ${ADMIN_USER}:${ADMIN_USER} "/home/${ADMIN_USER}/data" 2>/dev/null || true
        echo "${ADMIN_PASSWORD}" | sudo -S chmod -R 755 "/home/${ADMIN_USER}/data"
        echo "[OK] Carpetas de datos creadas en /home/${ADMIN_USER}/data"

        # 3. Limpieza de entorno
        rm -rf /home/${ADMIN_USER}/inception

        echo "===================================================="
        echo "  ¡VM lista! Entra, clona tu repo en tu HOME y ejecuta make"
        echo "===================================================="
EOF
fi

success "Provisioning for '$VM_NAME' complete."
