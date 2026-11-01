# ¿Qué se rompió y cómo se arregló?

## TL;DR

Registro de los fallos encontrados durante el desarrollo y su solución. Ninguno queda abierto; todos tienen prueba que lo cubre.

## 2026-09-24

### F1. El asistente de Android Studio hardcodea `~/Android/Sdk`

**Síntoma**: el IDE ignora `ANDROID_HOME` y persiste la ruta del SDK en el perfil del usuario, rompiendo la portabilidad.

**Causa**: el wizard y algunos componentes internos calculan la ruta del SDK contra `$HOME` en vez de usar las variables de entorno.

**Solución**: el lanzador reescribe `AndroidStudioConfig/options/AndroidSdkPathStore.xml` con la ruta real (`src/studio-portable.sh.in`) y crea el symlink `$HOME/Android/Sdk -> BASE/sdk` (`ln -sfn`) para los componentes que solo la saben leer de `$HOME`.

**Cobertura**: `blackbox_launcher.test.sh` (verifica el store con la ruta del destino y el symlink).

### F2. Test de idempotencia falso positivo

**Síntoma**: el test de idempotencia en la suite whitebox "pasaba" pero `setup.sh` fallaba en ambas corridas.

**Causa**: el test referenciaba un tar.gz que nunca se creaba; al fallar `setup.sh` dos veces, los hashes vacíos coincidían.

**Solución**: construir un tar.gz mínimo real en la suite antes de correr `setup.sh` dos veces (`tests/whitebox_content.test.sh`).

**Cobertura**: `whitebox_content.test.sh` — ahora los hashes comparan una instalación real e idempotente.

### F3. Fuga del identificador del operador en el repo

**Síntoma**: el usuario del operador aparecía en `LICENSE` y en las aserciones de prueba.

**Causa**: copyright y strings de verificación redactados con el nombre real.

**Solución**: reemplazado por el placeholder `usuario` (sin valor léxico), manteniendo las aserciones anti-fuga.

**Cobertura**: `whitebox_content.test.sh` y `blackbox_launcher.test.sh` verifican que ni templates ni estado del SDK contienen un identificador de usuario.

### F4. Extracción tar.gz sin guardas de path traversal

**Síntoma**: `setup.sh` extraía un tar.gz (posiblemente descargado de una URL) sin validar sus entradas.

**Causa**: `tar -xzf` directo; un tar hostil con rutas absolutas o `..` podría escribir fuera del destino.

**Solución**: antes de extraer se lista el contenido y se rechaza cualquier entrada absoluta o con travesía de directorio; la extracción usa `--no-same-owner` (`setup.sh`).

**Cobertura**: la suite blackbox de setup ejecuta el flujo completo; la validación se ejecuta siempre que hay tar.gz.

### F5. Gradle 8.14 no soporta Java 25 del SDK

**Síntoma**: el build de humo fallaba con `Unsupported class file major version 69`.

**Causa**: la matriz de compatibilidad oficial exige Gradle 9.1.0+ para correr con JDK 25 (docs.gradle.org/userguide/compatibility.html, versión 9.3.0, consulta 2026-09-24).

**Solución**: el bot usa el JBR de Android Studio (`jbr/bin/java`, JDK 25.0.3) y Gradle 9.1.0.

**Cobertura**: `05-build-gradle` del bot, hoy PASS.

### F6. El JDK del sistema es un JRE sin `javac`

**Síntoma**: el daemon de Gradle encontraba el toolchain `/usr/lib/jvm/java-25-openjdk` pero fallaba por falta de `JAVA_COMPILER`.

**Causa**: en el equipo, el paquete del sistema es el runtime (sin compilador); el único `javac` disponible está en el JBR del portable.

**Solución**: el bot exporta `JAVA_HOME="$PORTABLE/android-studio/jbr"` antes del build, manteniendo la autocontención.

**Cobertura**: `05-build-gradle` del bot, hoy PASS.

### F7. `android.jar` no entraba al classpath de compilación

**Síntoma**: build fallaba con `package android.app does not exist`; Gradle compilaba sin el SDK.

**Causa**: `-PandroidJar` apuntaba al directorio `platforms/android-37.0` en vez del archivo `android.jar` que contiene.

**Solución**: el bot pasa `-PandroidJar="$dir/android.jar"` y verifica que exista el jar resultante.

**Cobertura**: `05-build-gradle` del bot, hoy PASS.

## 2026-11-01

### F8. El instalador de emulador descargaba 150 MB antes de avisar que faltaba `unzip`

**Síntoma**: al correr `install-emulator.sh` en un sistema sin `unzip`, el script bajaba completo el zip de cmdline-tools y recién al final fallaba con `Falta unzip`.

**Causa**: el chequeo de `unzip` estaba después de la descarga, dentro de `install_cmdline_tools`.

**Solución**: la dependencia se valida **antes** de resolver la URL y descargar (`install-emulator.sh`), con mensaje que indica cómo instalarla o usar `--sdkmanager`.

**Cobertura**: `blackbox_install_emulator.test.sh` — sin `unzip` falla con código 1, el mensaje nombra la dependencia y no se invoca `curl`.

### F9. La primera instalación no verificaba el sha256 del IDE

**Síntoma**: `setup.sh` descargaba el tar.gz de Android Studio y lo extraía sin comparar checksum; solo `update_ide` verificaba. La documentación decía que se verificaba siempre.

**Causa**: la verificación se agregó en el flujo de actualización (`src/lib-portable.sh`) y no se replicó en el alta inicial de `setup.sh`, que además tenía su propia copia de `stable_url`.

**Solución**: `setup.sh` toma url y sha256 juntos de la página oficial (`page_manifest`), compara con `sha256sum` antes de extraer y descarta la descarga si no coincide. Con `--tar` propio el checksum se fija con `PORTABLE_IDE_SHA256`. Se eliminó la `stable_url` duplicada.

**Cobertura**: `blackbox_setup.test.sh` — sha256 correcto instala y avisa; sha256 incorrecto falla con código 1, no extrae el IDE y el mensaje explica el motivo.

### F10. La instalación normal desde cero fallaba: `page_manifest` moría bajo `pipefail`

**Síntoma**: en un clon limpio, `./setup.sh --dest <dir>` (sin `--tar`) abortaba de inmediato con `Fallo al resolver la URL estable`, aunque la misma resolución funcionaba a mano desde el lanzador.

**Causa**: `page_manifest` resuelve la fila Linux de la página oficial con `sed ... | awk`, y el `awk` hacía `exit` al encontrar la fila. Bajo `set -o pipefail` (que usa `setup.sh`, pero no el lanzador) el `sed` moría con SIGPIPE (rc 141), la tubería completa devolvía error y la función retornaba 1. Los tests herméticos no lo veían porque no ejercitaban la función dentro de un contexto `pipefail` con una página real.

**Solución**: el `awk` ya no corta la entrada: acumula la fila encontrada con `found = 1` y sigue consumiendo hasta el final; además todos los `| head -n 1` de `src/lib-portable.sh` pasaron a `sed -n '1p'` (8 casos), que termina sin cerrar el pipe antes de tiempo.

**Cobertura**: `whitebox_content.test.sh` — `setup.sh` corre con `pipefail`, `lib-portable` no contiene `| head -n`, y `page_manifest` devuelve el sha256 de la fila correcta ejecutada bajo `pipefail`. Verificado además con una instalación real completa (descarga del IDE oficial, sha256 del sitio y arranque del IDE).

## Registro automático del bot de validación

<!-- bot:inicio -->
_Registro automático del bot de validación — no editar a mano._

- **05-build-gradle**: resuelto (resuelto 2026-09-24)
<!-- bot:fin -->

> Over to you: si aparece un fallo nuevo, documentalo con el mismo formato (síntoma → causa → solución → cobertura) y agregá el test que lo reproduzca antes de considerar cerrado.
