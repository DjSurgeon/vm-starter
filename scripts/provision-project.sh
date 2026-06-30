#!/bin/bash
# =============================================================================
# scripts/provision-project.sh – Configure project-specific tools in the VM
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
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

    echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sh -c "cat << 'EOF_MOTD' > /etc/update-motd.d/99-devpod
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
        set -e
        echo "⏳ Waiting for apt locks to clear..."
        while echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done
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
        echo "  Clean Inception Provisioning for: ${REMOTE_ADMIN_USER}"
        echo "===================================================="

        # 1. Configuración Real del archivo /etc/hosts
        echo "Fixing /etc/hosts inside the VM..."
        if ! grep -q "${REMOTE_INCEPTION_DOMAIN}" /etc/hosts; then
            echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sh -c "echo '127.0.0.1    ${REMOTE_INCEPTION_DOMAIN}' >> /etc/hosts" > /dev/null
            echo "[OK] Domain ${REMOTE_INCEPTION_DOMAIN} successfully bound to 127.0.0.1"
        fi

        # 2. Estructura de Persistencia en el Host
        echo "Creating physical volume paths on the host..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${REMOTE_ADMIN_USER}/data/mariadb"
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S mkdir -p "/home/${REMOTE_ADMIN_USER}/data/wordpress"
        
        # Asegurar permisos
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chown -R "${REMOTE_ADMIN_USER}:${REMOTE_ADMIN_USER}" "/home/${REMOTE_ADMIN_USER}/data" 2>/dev/null || true
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S chmod -R 755 "/home/${REMOTE_ADMIN_USER}/data"
        echo "[OK] Data directories successfully created at /home/${REMOTE_ADMIN_USER}/data"

        # 3. Environment cleanup
        rm -rf "/home/${REMOTE_ADMIN_USER}/inception"

        echo "===================================================="
        echo "  VM ready! SSH into the machine, clone your repo in your HOME, and run make"
        echo "===================================================="
EOF

elif [ "$PROJECT_TYPE" = "inception-gui" ]; then
    log "Running clean provisioning for Inception GUI..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_USER" "$ADMIN_PASSWORD" "$INCEPTION_DOMAIN" <<'EOF'
        REMOTE_ADMIN_USER="$1"
        REMOTE_ADMIN_PASSWORD="$2"
        REMOTE_INCEPTION_DOMAIN="$3"

        echo "===================================================="
        echo "  Inception GUI Provisioning for: ${REMOTE_ADMIN_USER}"
        echo "===================================================="

        # 1. Host mapping
        echo "Fixing /etc/hosts inside the VM..."
        if ! grep -q "${REMOTE_INCEPTION_DOMAIN}" /etc/hosts; then
            echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S sh -c "echo '127.0.0.1    ${REMOTE_INCEPTION_DOMAIN}' >> /etc/hosts" > /dev/null
            echo "[OK] Domain ${REMOTE_INCEPTION_DOMAIN} successfully bound to 127.0.0.1"
        fi

        # 2. Environment cleanup (No data directories created to keep it clean)
        rm -rf "/home/${REMOTE_ADMIN_USER}/inception"

        # 3. GUI Installation
        echo "⏳ Waiting for apt locks to clear..."
        while echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done
        
        echo "📦 Installing Minimal XFCE Environment and Epiphany Browser..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xfce4 xfce4-session xinit xserver-xorg xserver-xorg-legacy epiphany-browser >/dev/null

        echo "🔧 Configuring X11 Permissions and Spanish Keyboard..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S bash -c 'cat << "EOF_X11" > /etc/X11/Xwrapper.config
allowed_users=anybody
needs_root_rights=yes
EOF_X11'

        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S mkdir -p /etc/X11/xorg.conf.d
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S bash -c 'cat << "EOF_KBD" > /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "es"
EndSection
EOF_KBD'

        echo "===================================================="
        echo "  VM ready! SSH into the machine, clone your repo, and run 'startx' to launch GUI"
        echo "===================================================="
EOF


elif [ "$PROJECT_TYPE" = "c-pure" ]; then
    log "Provisioning C-Pure environment for 42 Cursus..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_USER" "$ADMIN_PASSWORD" "\"$CPURE_PACKAGES\"" <<'EOF'
        REMOTE_ADMIN_USER="$1"
        REMOTE_ADMIN_PASSWORD="$2"
        REMOTE_CPURE_PACKAGES="$3"

        set -e

        echo "===================================================="
        echo "  C-Pure Provisioning (42 Cursus)"
        echo "===================================================="

        echo "⏳ Waiting for apt locks to clear..."
        while echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done

        # 1. Install base C tools
        echo "📦 Installing compilers and core tools..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y $REMOTE_CPURE_PACKAGES

        # 2. Install Norminette via pipx
        echo "📏 Installing official 42 Norminette..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" pipx install norminette
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" pipx ensurepath

        # 3. Configure .bashrc aliases and environment variables
        echo "🔧 Configuring strict environment in .bashrc..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" bash -c 'cat << "EOF_BASHRC" >> ~/.bashrc

# ==========================================
# 42 CURSUS - C-PURE ALIASES & CONFIG
# ==========================================
export CC=cc
export CFLAGS="-Wall -Wextra -Werror -g3"

alias gcc42="gcc -Wall -Wextra -Werror"
alias clang42="clang -Wall -Wextra -Werror"
alias vcheck="valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes"
EOF_BASHRC'

        echo "✅ C-Pure environment successfully configured."
EOF

elif [ "$PROJECT_TYPE" = "cpp-98" ]; then
    log "Provisioning C++98 strict environment for 42 Cursus..."
    ssh -q -o StrictHostKeyChecking=no "$VM_NAME" "bash -s" -- "$ADMIN_USER" "$ADMIN_PASSWORD" "\"$CPP98_PACKAGES\"" <<'EOF'
        REMOTE_ADMIN_USER="$1"
        REMOTE_ADMIN_PASSWORD="$2"
        REMOTE_CPP98_PACKAGES="$3"

        set -e

        echo "===================================================="
        echo "  C++98 Provisioning (42 Cursus)"
        echo "===================================================="

        echo "⏳ Waiting for apt locks to clear..."
        while echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done

        # 1. Install base C++ tools
        echo "📦 Installing C++ compilers and core tools..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y $REMOTE_CPP98_PACKAGES

        # 2. Configure Clang-Format (Google Style)
        echo "🎨 Configuring Clang-Format (Google Style)..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" bash -c 'clang-format -style=Google -dump-config > "$HOME/.clang-format"'
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" sed -i 's/IndentWidth: 2/IndentWidth: 4/g' "$HOME/.clang-format"

        # 3. Configure .bashrc aliases and strict compilation flags
        echo "🔧 Configuring strict C++98 environment in .bashrc..."
        echo "${REMOTE_ADMIN_PASSWORD}" | sudo -S -u "$REMOTE_ADMIN_USER" bash -c 'cat << "EOF_BASHRC" >> ~/.bashrc

# ==========================================
# 42 CURSUS - CPP-98 ALIASES & CONFIG
# ==========================================
alias c++42="g++ -Wall -Wextra -Werror -std=c++98"
alias clang++42="clang++ -Wall -Wextra -Werror -std=c++98"
alias cformat="clang-format -i *.cpp *.hpp 2>/dev/null || clang-format -i *.cpp *.h 2>/dev/null"

export CXX=g++
export CXXFLAGS="-Wall -Wextra -Werror -std=c++98 -g3"
EOF_BASHRC'

        echo "✅ C++98 environment successfully configured."
EOF
fi

success "Provisioning for '$VM_NAME' complete."
