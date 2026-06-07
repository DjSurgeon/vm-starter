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
    log "Creating Inception folder structure..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" <<EOF
        # Create physical data folders for Docker volumes on the host VM
        echo "${ADMIN_PASSWORD}" | sudo -S mkdir -p /home/${ADMIN_USER}/data/wordpress
        echo "${ADMIN_PASSWORD}" | sudo -S mkdir -p /home/${ADMIN_USER}/data/mariadb
        echo "${ADMIN_PASSWORD}" | sudo -S chown -R ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/data

        # Create Inception project root simulating the git repository
        mkdir -p ~/inception/${INCEPTION_SRCS_DIR}/requirements/nginx
        mkdir -p ~/inception/${INCEPTION_SRCS_DIR}/requirements/wordpress
        mkdir -p ~/inception/${INCEPTION_SRCS_DIR}/requirements/mariadb
        mkdir -p ~/inception/${INCEPTION_SECRETS_DIR}
        
        # Create Makefile at the root of the project
        cat <<'MK' > ~/inception/Makefile
all:
	cd srcs && docker compose up -d --build

down:
	cd srcs && docker compose down

clean: down
	docker system prune -a

fclean: clean
	sudo rm -rf /home/${ADMIN_USER}/data/wordpress/*
	sudo rm -rf /home/${ADMIN_USER}/data/mariadb/*

re: fclean all

.PHONY: all down clean fclean re
MK

        # Create docker-compose.yml stub in srcs/ with Named Volumes mapped to host path
        cat <<'DC' > ~/inception/${INCEPTION_SRCS_DIR}/docker-compose.yml
version: '3'
services:
  nginx:
    build: requirements/nginx
    ports:
      - "${INCEPTION_NGINX_PORT_HOST}:${INCEPTION_NGINX_PORT}"
    volumes:
      - wordpress_data:/var/www/html
      
  wordpress:
    build: requirements/wordpress
    volumes:
      - wordpress_data:/var/www/html
      
  mariadb:
    build: requirements/mariadb
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${ADMIN_USER}/data/wordpress
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${ADMIN_USER}/data/mariadb
DC

        # Create a basic .env stub in srcs/
        cat <<'ENV' > ~/inception/${INCEPTION_SRCS_DIR}/.env
DOMAIN_NAME=${INCEPTION_DOMAIN}
ENV
EOF
fi

success "Provisioning for '$VM_NAME' complete."
