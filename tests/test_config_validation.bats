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

@test "Config: El stack 'c-pure' debe asignar exactamente 1024MB de RAM y 1 CPU" {
    export PROJECT_ROOT
    source "${PROJECT_ROOT}/config/04-clones.sh"
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # Validamos que las variables existan y tengan el valor estricto esperado
    [ "$CPURE_CLONE_RAM_MB" -eq 1024 ]
    [ "$CPURE_CLONE_CPU" -eq 1 ]
    
    # Validamos que son estrictamente numéricas usando la librería base
    run validate_numeric "CPURE_CLONE_RAM_MB" "$CPURE_CLONE_RAM_MB"
    [ "$status" -eq 0 ]
    
    run validate_numeric "CPURE_CLONE_CPU" "$CPURE_CLONE_CPU"
    [ "$status" -eq 0 ]
}

@test "Config: El stack 'c-pure' debe incluir gcc, clang, gdb, valgrind, vim y pipx" {
    export PROJECT_ROOT
    source "${PROJECT_ROOT}/config/08-stack.sh"
    
    # Verificamos la presencia de herramientas críticas como subcadenas
    [[ "$CPURE_PACKAGES" == *"gcc"* ]]
    [[ "$CPURE_PACKAGES" == *"clang"* ]]
    [[ "$CPURE_PACKAGES" == *"gdb"* ]]
    [[ "$CPURE_PACKAGES" == *"valgrind"* ]]
    [[ "$CPURE_PACKAGES" == *"pipx"* ]]
    [[ "$CPURE_PACKAGES" == *"vim"* ]]
}

@test "Config: El stack 'cpp-98' debe asignar exactamente 2048MB de RAM y 1 CPU" {
    export PROJECT_ROOT
    source "${PROJECT_ROOT}/config/04-clones.sh"
    source "${PROJECT_ROOT}/config/99-functions.sh"
    
    # Validamos que las variables existan y tengan el valor estricto esperado
    [ "$CPP98_CLONE_RAM_MB" -eq 2048 ]
    [ "$CPP98_CLONE_CPU" -eq 1 ]
    
    # Validamos que son estrictamente numéricas usando la librería base
    run validate_numeric "CPP98_CLONE_RAM_MB" "$CPP98_CLONE_RAM_MB"
    [ "$status" -eq 0 ]
    
    run validate_numeric "CPP98_CLONE_CPU" "$CPP98_CLONE_CPU"
    [ "$status" -eq 0 ]
}

@test "Config: El stack 'cpp-98' debe incluir g++ y clang-format" {
    export PROJECT_ROOT
    source "${PROJECT_ROOT}/config/08-stack.sh"
    
    # Verificamos la presencia de herramientas críticas como subcadenas
    [[ "$CPP98_PACKAGES" == *"g++"* ]]
    [[ "$CPP98_PACKAGES" == *"clang-format"* ]]
}
