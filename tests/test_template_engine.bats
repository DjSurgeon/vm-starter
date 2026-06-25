#!/usr/bin/env bats

load setup

@test "Template: Pre-flight check must fail immediately if ISO creation tools are missing" {
    # 1. Setup the test environment
    export PROJECT_ROOT
    
    # 2. Mock 'error' function to prevent premature bats exit
    # shellcheck disable=SC2317
    error() {
        echo "ERROR: $1"
        exit 1
    }
    export -f error
    
    # 3. Mock the 'command' builtin
    # This intercepts the check to simulate a missing ISO generation tool
    # while allowing other dependencies (VBoxManage, curl, wget) to pass safely.
    # shellcheck disable=SC2317
    command() {
        if [ "$1" == "-v" ]; then
            if [ "$2" == "genisoimage" ] || [ "$2" == "mkisofs" ]; then
                return 1 # Simulate "not found"
            fi
            if [ "$2" == "VBoxManage" ] || [ "$2" == "curl" ] || [ "$2" == "wget" ]; then
                return 0 # Simulate "found"
            fi
        fi
        builtin command "$@"
    }
    export -f command

    # 4. Execute the actual pre-flight check in an isolated subshell
    run bash -c "
        source \"${PROJECT_ROOT}/config/99-functions.sh\"
        export -f error
        export -f command
        source \"${PROJECT_ROOT}/template/lib/01-check-env.sh\"
        check_env
    "

    # 5. Assertions
    [ "$status" -ne 0 ]
    [[ "$output" == *"Command 'genisoimage' or 'mkisofs' not found"* ]]
}
