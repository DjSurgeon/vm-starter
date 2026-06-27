# VM-Starter: Manual QA & Security Testing Checklist 🧪

Este listado está diseñado para que pongas a prueba la resiliencia de la infraestructura de extremo a extremo. Cubre desde pruebas de funcionalidad básica hasta intentos de inyección y ataques de validación.

Usa este documento para marcar (check) cada prueba conforme la vayas ejecutando manualmente en tu entorno.

---

## 1. Pruebas de Seguridad y Sanitización (Red Teaming)

Vamos a intentar "romper" el script `make create` mediante inputs maliciosos.

- [ ] **Test 1.1: Inyección de Comandos en el Nombre**
  - **Acción:** Ejecuta `make create` y cuando pida el nombre, introduce: `test; rm -rf /` o `test && echo "hacked"`
  - **Esperado:** El script debe abortar inmediatamente con un error de validación (gracias a `validate_project_name`). No debe ejecutarse el comando inyectado.

- [ ] **Test 1.2: Directory Traversal (Escalada de Directorios)**
  - **Acción:** Como nombre del proyecto, introduce: `../../../etc/shadow` o `../mi-proyecto`
  - **Esperado:** El script debe abortar. Solo se permiten caracteres alfanuméricos y guiones medios.

- [ ] **Test 1.3: Nombre Vacío o Espacios**
  - **Acción:** Introduce un nombre vacío (solo dale a Enter) o un nombre con espacios `mi proyecto`.
  - **Esperado:** El script debe abortar o volver a pedir el nombre, sin intentar crear una máquina virtual llamada `.ova` o crashear.

---

## 2. Pruebas de los Nuevos Entornos (C-Pure y C++98)

Vamos a verificar que los entornos que acabamos de programar funcionan en la vida real.

### Entorno C-Pure
- [ ] **Test 2.1: Creación y Límites de Recursos**
  - **Acción:** Ejecuta `make create`, llámalo `libft-test`, y selecciona `C-Pure`.
  - **Esperado:** El asistente levanta la máquina. Abre VirtualBox (la interfaz gráfica) y comprueba en la configuración de la VM `cpure-libft-test`:
    - RAM: Exactamente `1024 MB`.
    - Procesadores: Exactamente `1 CPU`.
- [ ] **Test 2.2: Aprovisionamiento y Alias**
  - **Acción:** Entra con `make ssh NAME=cpure-libft-test`.
  - **Esperado:**
    - `gcc --version` y `valgrind --version` devuelven la versión instalada.
    - `norminette -v` funciona correctamente (gracias a `pipx`).
    - Al ejecutar `env | grep CC`, aparece `CC=cc`.
    - Al escribir `alias`, aparecen `gcc42`, `clang42` y `vcheck`.

### Entorno C++98
- [ ] **Test 2.3: Creación y Límites de Recursos**
  - **Acción:** Ejecuta `make create`, llámalo `cpp-module00`, y selecciona `C++98`.
  - **Esperado:** En la GUI de VirtualBox, la VM `cpp-cpp-module00` debe tener:
    - RAM: Exactamente `2048 MB`.
    - Procesadores: Exactamente `1 CPU`.
- [ ] **Test 2.4: Linter de Google (Clang-Format)**
  - **Acción:** Entra con `make ssh NAME=cpp-cpp-module00`. Crea un archivo caótico `main.cpp`:
    ```cpp
    #include <iostream>
    int main(){if(true){std::cout<<"Hola" ;}return 0;}
    ```
  - **Esperado:** Ejecuta el alias `cformat`. El archivo `main.cpp` debe autoformatearse de forma limpia con 4 espacios de indentación.
  - **Esperado:** Comprueba que existe el archivo `~/.clang-format` y que contiene la directiva `IndentWidth: 4`.

---

## 3. Pruebas de Resiliencia del Asistente y Red

- [ ] **Test 3.1: Cancelación Interactiva**
  - **Acción:** Lanza `make create`. En la pantalla final de *"Does this look correct?"*, elige `Cancel`.
  - **Esperado:** El proceso debe terminar limpiamente (`exit 0`) sin dejar archivos temporales corruptos y sin llamar a VirtualBox.

- [ ] **Test 3.2: Asignación Dinámica de Puertos SSH (Simulación de Colisión)**
  - **Acción:** Con una máquina ya levantada (por ejemplo, en el puerto `4222`), usa `nc -l 4223` en otra terminal de tu máquina Host para bloquear manualmente el siguiente puerto. Luego ejecuta `make create` para crear una nueva VM.
  - **Esperado:** El script de clonación debe detectar que el puerto `4223` está ocupado, saltarlo, y asignar el puerto `4224` a la nueva máquina virtual para evitar conflictos.

- [ ] **Test 3.3: Configuración SSH Inmutable**
  - **Acción:** Crea dos veces máquinas con el mismo nombre (ej. creas `web-test`, haces `make fclean`, y vuelves a crear `web-test`). Revisa tu archivo `~/.ssh/config` local.
  - **Esperado:** El script debe haber reemplazado limpiamente la configuración antigua (usando `sed`), y no deberías tener dos bloques de configuración duplicados para el mismo `Host`.

---

## 4. Pruebas de Destrucción (Fclean)

- [ ] **Test 4.1: Borrado Seguro Total**
  - **Acción:** Con varias VMs levantadas, ejecuta `make fclean`.
  - **Esperado:** Todas las VMs (c-pure, cpp-98, web) deben apagarse a la fuerza y eliminarse de VirtualBox. 
  - **Esperado:** El `~/.ssh/config` debe purgarse de las entradas de DevPod.
  - **Cuidado:** Verifica que la carpeta `/home/dev/data` (en el caso de Inception) se borre o se mantenga según la política de borrado que tengas estipulada.

---

> [!TIP]
> Si logras romper algo en la **Sección 1 (Inyecciones)** o en la **Sección 2 (Aprovisionamiento)**, significa que hay un agujero que los tests automatizados de BATS no han cubierto. Si pasas todas estas pruebas manualmente de forma satisfactoria, puedes considerar el proyecto oficialmente `Enterprise-Ready`.