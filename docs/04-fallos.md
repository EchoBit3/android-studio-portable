# Fallos resueltos

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

## Registro automático del bot de validación

<!-- bot:inicio -->
_Registro automático del bot de validación — no editar a mano._

- **05-build-gradle**: resuelto (resuelto 2026-09-24)
<!-- bot:fin -->
