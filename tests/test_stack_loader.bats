#!/usr/bin/env bats

load setup

@test "Plugins: Dynamic loader must process valid configs sequentially" {
    # 1. Dependency Injection setup
    MOCK_CONFIG_DIR="${BATS_TMPDIR}/mock_config_valid"
    export MOCK_CONFIG_DIR
    mkdir -p "$MOCK_CONFIG_DIR"
    
    # 2. Create valid dummy config files
    echo 'export STACK_TYPE_A="active"' > "${MOCK_CONFIG_DIR}/01-typeA.sh"
    echo 'export STACK_TYPE_B="active"' > "${MOCK_CONFIG_DIR}/02-typeB.sh"
    touch "${MOCK_CONFIG_DIR}/99-functions.sh" # Prevent warnings
    
    # 3. Execute the real dynamic loader
    run bash -c "
        set -e
        # shellcheck disable=SC1091
        source \"${PROJECT_ROOT}/config/config.sh\"
        echo \"STATUS: \${STACK_TYPE_A}-\${STACK_TYPE_B}\"
    "
    
    # 4. Assertions
    [ "$status" -eq 0 ]
    [[ "$output" == *"STATUS: active-active"* ]]
    
    # 5. Cleanup
    rm -rf "$MOCK_CONFIG_DIR"
}

@test "Plugins: Dynamic loader must apply 'Fail Fast' and abort if a module fails" {
    # 1. Dependency Injection setup
    MOCK_CONFIG_DIR="${BATS_TMPDIR}/mock_config_corrupt"
    export MOCK_CONFIG_DIR
    mkdir -p "$MOCK_CONFIG_DIR"
    
    # 2. Create a corrupt module
    echo 'echo "Loading corrupt module..."' > "${MOCK_CONFIG_DIR}/01-corrupt.sh"
    echo 'false' >> "${MOCK_CONFIG_DIR}/01-corrupt.sh" # Induce failure (exit code 1)
    echo 'export STACK_SHOULD_NOT_LOAD="yes"' > "${MOCK_CONFIG_DIR}/02-neverReached.sh"
    touch "${MOCK_CONFIG_DIR}/99-functions.sh"
    
    # 3. Execute the real dynamic loader enforcing fail-fast
    run bash -c "
        set -e
        # shellcheck disable=SC1091
        source \"${PROJECT_ROOT}/config/config.sh\"
        echo \"REACHED: \${STACK_SHOULD_NOT_LOAD}\"
    "
    
    # 4. Assertions: Must fail globally and block subsequent modules
    [ "$status" -ne 0 ]
    [[ "$output" != *"REACHED: yes"* ]]
    
    # 5. Cleanup
    rm -rf "$MOCK_CONFIG_DIR"
}
