#!/usr/bin/env bats

load setup

@test "Config: Critical hardware variables must be strictly numeric" {
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # Valid values
    VM_RAM="2048"
    VM_CPU="2"

    run validate_numeric "VM_RAM" "$VM_RAM"
    [ "$status" -eq 0 ]
    
    run validate_numeric "VM_CPU" "$VM_CPU"
    [ "$status" -eq 0 ]
}

@test "Config: Should detect and reject corrupt or non-numeric hardware configurations" {
    export PROJECT_ROOT
    
    # Invalid value with letters
    VM_RAM="4GB" 

    run bash -c "
        source \"${PROJECT_ROOT}/config/99-functions.sh\"
        
        # Mock 'error' function to prevent premature bats exit
        # shellcheck disable=SC2317
        error() {
            echo \"ERROR: \$1\"
            exit 1
        }
        export -f error
        
        validate_numeric 'VM_RAM' '${VM_RAM}'
    "
    
    [ "$status" -ne 0 ]
    [[ "$output" == *"Validation Error: VM_RAM must be a strictly numeric value"* ]]
}
