#!/usr/bin/env bats

load setup

setup_file() {
    export FAKE_GOINFRE="${BATS_TMPDIR}/fake_goinfre"
    # PROJECT_ROOT is loaded from setup.bash, so we don't define TEST_LOCAL_ENV here 
    # until after setup() runs. We'll define it dynamically in the test.
}

teardown_file() {
    rm -rf "$FAKE_GOINFRE"
}

@test "Storage: init-env debe configurar VirtualBox y crear la referencia local_env.sh" {
    export TEST_LOCAL_ENV="${PROJECT_ROOT}/config/local_env.sh"
    mkdir -p "$FAKE_GOINFRE"
    
    # Creamos el Mock de VBoxManage en el directorio generado por setup.bash
    echo '#!/bin/bash' > "${MOCK_BIN_DIR}/VBoxManage"
    echo 'echo "Mock VBoxManage ejecutado con éxito: $*" >> "'"${MOCK_BIN_DIR}/vbox_history.log"'"' >> "${MOCK_BIN_DIR}/VBoxManage"
    chmod +x "${MOCK_BIN_DIR}/VBoxManage"

    # Simulación de las respuestas del prompt interactivo usando un HereDoc/String
    # 1. Opción 3 (Ruta customizada)
    # 2. La ruta FAKE_GOINFRE
    # 3. El nombre de usuario dev_user
    run bash -c "${PROJECT_ROOT}/scripts/init-env.sh <<< $'3\n${FAKE_GOINFRE}\ndev_user\n'"
    
    [ "$status" -eq 0 ]
    
    # 1. Comprobamos que el wrapper de VirtualBox se invocó con los flags correctos
    run cat "${MOCK_BIN_DIR}/vbox_history.log"
    [[ "$output" == *"setproperty machinefolder ${FAKE_GOINFRE}"* ]]
    
    # 2. Comprobamos que el artefacto de persistencia local se generó correctamente
    [ -f "$TEST_LOCAL_ENV" ]
    
    run grep "export DEVPOD_ROOT=\"${FAKE_GOINFRE}\"" "$TEST_LOCAL_ENV"
    [ "$status" -eq 0 ]
    
    run grep "export ADMIN_USER=\"dev_user\"" "$TEST_LOCAL_ENV"
    [ "$status" -eq 0 ]
    
    # Limpieza local
    rm -f "$TEST_LOCAL_ENV"
}
