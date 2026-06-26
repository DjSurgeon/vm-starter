#!/bin/bash
# =============================================================================
# scripts/clone.sh – Create a project VM from the base template
# =============================================================================

set -e

# 1. Load central configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/config/config.sh" || { echo "❌ Error: Could not load config.sh"; exit 1; }

# -----------------------------------------------------------------------------
# 2. Input Validation
# -----------------------------------------------------------------------------
check_not_root

PROJECT_NAME="$1"
PROJECT_TYPE="$2"

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_TYPE" ]; then
    error "Usage: $0 <name> <type (web|inception)>"
fi

validate_project_name "$PROJECT_NAME"

if [[ "$PROJECT_TYPE" != "web" && "$PROJECT_TYPE" != "inception" && "$PROJECT_TYPE" != "c-pure" ]]; then
    error "Invalid project type: $PROJECT_TYPE. Must be 'web', 'inception', or 'c-pure'."
fi

# Ensure base template exists
if ! VBoxManage showvminfo "$TEMPLATE_NAME" >/dev/null 2>&1; then
    error "Base template '$TEMPLATE_NAME' not found. Run 'make template' first."
fi

# -----------------------------------------------------------------------------
# 3. Resource and Name Calculation
# -----------------------------------------------------------------------------
if [ "$PROJECT_TYPE" = "web" ]; then
    PREFIX="$WEB_PREFIX"
    RAM="$WEB_CLONE_RAM_MB"
    CPU="$WEB_CLONE_CPU"
elif [ "$PROJECT_TYPE" = "c-pure" ]; then
    PREFIX="$CPURE_PREFIX"
    RAM="$CPURE_CLONE_RAM_MB"
    CPU="$CPURE_CLONE_CPU"
else
    PREFIX="$INCEPTION_PREFIX"
    RAM="$INCEPTION_CLONE_RAM_MB"
    CPU="$INCEPTION_CLONE_CPU"
fi

VM_NAME="${PREFIX}-${PROJECT_NAME}"

# Ensure VM doesn't already exist
if VBoxManage showvminfo "$VM_NAME" >/dev/null 2>&1; then
    error "VM '$VM_NAME' already exists. Choose a different name."
fi

# -----------------------------------------------------------------------------
# 4. Cloning the VM
# -----------------------------------------------------------------------------
log "Cloning template '$TEMPLATE_NAME' into project VM '$VM_NAME'..."
VBoxManage clonevm "$TEMPLATE_NAME" --name "$VM_NAME" --register --basefolder "${DISK_IMAGES_DIR}" --mode all --options keepallmacs --options keepdisknames

# -----------------------------------------------------------------------------
# 5. Resource Allocation
# -----------------------------------------------------------------------------
log "Configuring resources: ${RAM}MB RAM, ${CPU} CPUs..."
VBoxManage modifyvm "$VM_NAME" --memory "$RAM" --cpus "$CPU"

# -----------------------------------------------------------------------------
# 6. Dynamic Port Allocation
# -----------------------------------------------------------------------------
log "Finding an available host port for SSH..."

AVAILABLE_PORT=$(get_available_ssh_port "$SSH_PORT_RANGE_START" "$SSH_PORT_RANGE_END") || true

if [ -z "$AVAILABLE_PORT" ]; then
    error "No available ports found in range ${SSH_PORT_RANGE_START}-${SSH_PORT_RANGE_END}."
fi

success "Selected port: $AVAILABLE_PORT"

# Add NAT port forwarding rule
log "Setting up SSH port forwarding (Host:${AVAILABLE_PORT} -> VM:${SSH_VM_PORT})..."
VBoxManage modifyvm "$VM_NAME" --natpf1 delete "guestssh" 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 "guestssh,tcp,,$AVAILABLE_PORT,,$SSH_VM_PORT"

# -----------------------------------------------------------------------------
# 7. SSH Config Update
# -----------------------------------------------------------------------------
log "Updating ~/.ssh/config for alias '$VM_NAME'..."
update_ssh_config "$VM_NAME" "$ADMIN_USER" "$AVAILABLE_PORT"

# -----------------------------------------------------------------------------
# 8. Project Provisioning
# -----------------------------------------------------------------------------
log "Waiting for VM to boot for provisioning..."
# Start the VM to provision it
VBoxManage startvm "$VM_NAME" --type headless

# Wait for SSH to be ready
log "Waiting for SSH to be ready on port $AVAILABLE_PORT..."
for _ in {1..60}; do
    if ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -p "$AVAILABLE_PORT" "${ADMIN_USER}@127.0.0.1" exit 2>/dev/null; then
        break
    fi
    sleep 2
done

# Run provisioning script
if [ -f "${PROJECT_ROOT}/scripts/provision-project.sh" ]; then
    log "Running project provisioning..."
    "${PROJECT_ROOT}/scripts/provision-project.sh" "$VM_NAME" "$PROJECT_TYPE"
else
    warn "Provisioning script not found at scripts/provision-project.sh"
fi

success "Project '$VM_NAME' created successfully!"
info "To connect, run: make ssh NAME=$VM_NAME or simply: ssh $VM_NAME"
