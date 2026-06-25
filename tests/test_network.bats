#!/usr/bin/env bats

# =============================================================================
# tests/test_network.bats – Smart Port Allocation tests
# =============================================================================

load setup

@test "Network: Should allocate the first port (2222) if available" {
    # Mock VBoxManage to return no VMs or used ports
    cat << 'EOF' > "${MOCK_BIN_DIR}/VBoxManage"
#!/bin/bash
exit 0
EOF
    chmod +x "${MOCK_BIN_DIR}/VBoxManage"

    # Load the function to test
    source "${PROJECT_ROOT}/config/99-functions.sh"

    run get_available_ssh_port 2222 2299
    
    [ "$status" -eq 0 ]
    [ "$output" -eq 2222 ]
}

@test "Network: Should jump to 2223 if 2222 is busy" {
    # Mock VBoxManage to simulate that 2222 is occupied
    cat << 'EOF' > "${MOCK_BIN_DIR}/VBoxManage"
#!/bin/bash
if [ "$1" = "list" ]; then
    echo '"testvm" {uuid}'
    exit 0
fi
if [ "$1" = "showvminfo" ]; then
    echo 'Forwarding(1)="guestssh,tcp,,2222,,22"'
    exit 0
fi
EOF
    chmod +x "${MOCK_BIN_DIR}/VBoxManage"

    source "${PROJECT_ROOT}/config/99-functions.sh"

    run get_available_ssh_port 2222 2299
    
    [ "$status" -eq 0 ]
    [ "$output" -eq 2223 ]
}

@test "Network: Should fail (return 1) if all ports are busy" {
    cat << 'EOF' > "${MOCK_BIN_DIR}/VBoxManage"
#!/bin/bash
if [ "$1" = "list" ]; then
    echo '"vm1" {uuid1}'
    echo '"vm2" {uuid2}'
    exit 0
fi
if [ "$1" = "showvminfo" ]; then
    if [ "$2" = "vm1" ]; then echo 'Forwarding(1)="guestssh,tcp,,2222,,22"'; fi
    if [ "$2" = "vm2" ]; then echo 'Forwarding(1)="guestssh,tcp,,2223,,22"'; fi
    exit 0
fi
EOF
    chmod +x "${MOCK_BIN_DIR}/VBoxManage"

    source "${PROJECT_ROOT}/config/99-functions.sh"

    run get_available_ssh_port 2222 2223
    
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}
