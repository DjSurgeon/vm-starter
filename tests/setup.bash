#!/usr/bin/env bats

# =============================================================================
# tests/setup.bash – Global setup and teardown for Bats tests
# =============================================================================

setup() {
    # Creamos un directorio temporal para simular binarios del sistema (Mocks)
    MOCK_BIN_DIR="$(mktemp -d)"
    export MOCK_BIN_DIR
    export PATH="${MOCK_BIN_DIR}:${PATH}"
    
    # Exportar PROJECT_ROOT para que los tests puedan encontrar config/ y scripts/
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT
}

teardown() {
    # Limpiamos el directorio de mocks al finalizar
    if [ -n "$MOCK_BIN_DIR" ] && [ -d "$MOCK_BIN_DIR" ]; then
        rm -rf "$MOCK_BIN_DIR"
    fi
}
