#!/usr/bin/env bats

load setup

setup_file() {
    export SANDBOX_DIR="${BATS_TMPDIR}/sandbox_vm_starter"
}

teardown() {
    rm -rf "$SANDBOX_DIR"
}

@test "Security: Destructive command must abort if path variables are empty (SC1115)" {
    # Simulating business logic of vm-starter cleanup inside a function to avoid bash -c parsing issues
    simulate_cleanup() {
        rm -rf "${APP_DIR:?APP_DIR no está seteado}/${VERSION:?VERSION no está seteado}"
    }
    
    run simulate_cleanup
    
    [ "$status" -ne 0 ]
    [[ "$output" == *"APP_DIR no está seteado"* ]]
}

@test "Security: Must allow deletion if variables are valid and safe" {
    mkdir -p "${SANDBOX_DIR}/v1"
    touch "${SANDBOX_DIR}/v1/dummy.txt"

    export APP_DIR="$SANDBOX_DIR"
    export VERSION="v1"

    run bash -c 'rm -rf "${APP_DIR:?}/${VERSION:?}"'
    
    [ "$status" -eq 0 ]
    [ ! -d "${SANDBOX_DIR}/v1" ]
}

@test "Security: validate_project_name should reject directory traversal" {
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # We mock 'error' function to just exit 1 to test validation without killing bats prematurely
    error() { echo "$1"; exit 1; }
    export -f error
    
    run validate_project_name "../myvm"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
    
    run validate_project_name "myvm; rm -rf /"
    [ "$status" -eq 1 ]
    
    run validate_project_name "my-valid-vm123"
    [ "$status" -eq 0 ]
}

@test "Security: check_not_root should abort if running as root" {
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    error() { echo "$1"; exit 1; }
    export -f error
    
    # Simulate root execution via MOCK_EUID dependency injection
    export MOCK_EUID=0
    
    run check_not_root
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"should not be run as root"* ]]
}
