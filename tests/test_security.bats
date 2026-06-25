#!/usr/bin/env bats

# =============================================================================
# tests/test_security.bats – Security validation tests
# =============================================================================

load setup

setup_file() {
    # This runs once before the tests in this file
    export TEST_SSH_CONFIG="${BATS_TMPDIR}/test_ssh_config"
}

teardown() {
    # Clean up the test file after each test
    rm -f "$TEST_SSH_CONFIG"
}

@test "Security: Should correctly insert a new SSH config entry with security bypasses" {
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # Run the function pointing to our dummy config file
    run update_ssh_config "test-vm" "dev_user" "4222" "$TEST_SSH_CONFIG"
    
    [ "$status" -eq 0 ]
    [ -f "$TEST_SSH_CONFIG" ]
    
    # Check that the critical security bypasses are present
    run grep "StrictHostKeyChecking no" "$TEST_SSH_CONFIG"
    [ "$status" -eq 0 ]
    
    run grep "UserKnownHostsFile /dev/null" "$TEST_SSH_CONFIG"
    [ "$status" -eq 0 ]
    
    # Check that parameters are correctly parsed
    run grep "Port 4222" "$TEST_SSH_CONFIG"
    [ "$status" -eq 0 ]
}

@test "Security: Should cleanly replace an existing entry without duplication" {
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # First insertion
    update_ssh_config "test-vm" "dev_user" "4222" "$TEST_SSH_CONFIG"
    
    # Second insertion (simulating creating a VM with the same name, but new port)
    update_ssh_config "test-vm" "dev_user" "4223" "$TEST_SSH_CONFIG"
    
    # Count occurrences of the host block. Should be exactly 1.
    host_count=$(grep -c "^Host test-vm$" "$TEST_SSH_CONFIG")
    [ "$host_count" -eq 1 ]
    
    # Ensure it updated to the new port and the old one is gone
    run grep "Port 4223" "$TEST_SSH_CONFIG"
    [ "$status" -eq 0 ]
    
    run grep "Port 4222" "$TEST_SSH_CONFIG"
    [ "$status" -eq 1 ]
}
