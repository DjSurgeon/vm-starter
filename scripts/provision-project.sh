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
        sudo apt-get update -qq
        curl -fsSL https://deb.nodesource.com/setup_${DEV_NODE_VERSION}.x -o nodesource_setup.sh
        sudo -E bash nodesource_setup.sh >/dev/null 2>&1
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs >/dev/null 2>&1
        sudo npm install -g pnpm@${DEV_PNPM_VERSION} >/dev/null 2>&1
        rm -f nodesource_setup.sh
        mkdir -p ~/projects
EOF

elif [ "$PROJECT_TYPE" = "inception" ]; then
    log "Creating Inception folder structure..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" <<EOF
        mkdir -p ~/${INCEPTION_SRCS_DIR}
        mkdir -p ~/${INCEPTION_REQUIREMENTS_DIR}/nginx
        mkdir -p ~/${INCEPTION_REQUIREMENTS_DIR}/wordpress
        mkdir -p ~/${INCEPTION_REQUIREMENTS_DIR}/mariadb
        mkdir -p ~/${INCEPTION_SECRETS_DIR}
        
        # Create a basic docker-compose.yml stub
        cat <<'DC' > ~/${INCEPTION_SRCS_DIR}/docker-compose.yml
version: '3'
services:
  nginx:
    build: requirements/nginx
    ports:
      - "${INCEPTION_NGINX_PORT_HOST}:${INCEPTION_NGINX_PORT}"
DC
EOF
fi

success "Provisioning for '$VM_NAME' complete."
