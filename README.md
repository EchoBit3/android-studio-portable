# android-studio-portable

Android Studio autocontenido en un solo directorio: SDK, AVDs, Gradle, cachés, configuración JetBrains y temporales; movible y reproducible, sin binarios en el repo.

## Requisitos

- Linux (validado en Fedora) con bash 5.x
- `tar` y `curl` o `wget`
- Si usás el emulador: KVM activado

## Instalar

```bash
# 1. Cloná el repo
git clone https://github.com/<TU_USUARIO>/android-studio-portable.git
cd android-studio-portable

# 2. Corré las pruebas (opcional pero recomendado)
bash tests/run-tests.sh

# 3. Instalá portable (descarga el tar.gz oficial de Google ~1.5 GB)
#    Sin --tar, setup.sh resuelve la última versión estable desde
#    developer.android.com/studio y la descarga (requiere curl).
./setup.sh --dest "$HOME/AndroidStudio-Portable"

# 4. O usá un tar.gz ya descargado (no requiere red en el setup)
./setup.sh --dest "$HOME/AndroidStudio-Portable" --tar ~/Descargas/android-studio-*-linux.tar.gz

# 5. Lanzá
"$HOME/AndroidStudio-Portable/studio-portable.sh"
```

## Qué hace cada cosa

| Archivo | Rol |
|---|---|
| `setup.sh` | Crea la estructura, extrae el IDE, genera lanzador + config, enlaza `$HOME/Android/Sdk`. Flags: `--dest`, `--tar`, `--home`, `--no-symlink`, `--help`. |
| `uninstall.sh` | Revierte el setup. Flags: `--dest`, `--home`, `--keep-binaries`. |
| `src/studio-portable.sh.in` | Template del lanzador; deriva su ubicación en runtime. |
| `src/studio.properties.in` | Template de config JetBrains con rutas relativas. |
| `tests/` | Suites de caja negra y caja blanca. |
| `docs/` | Diseño, estrategia de pruebas, entorno de validación y fallos resueltos. |

## Cómo funciona la portabilidad

Flujo completo en `docs/assets/portable-flujo.mmd`. En una frase: el lanzador exporta `ANDROID_HOME`, `ANDROID_USER_HOME`, `ANDROID_AVD_HOME`, `GRADLE_USER_HOME`, las rutas XDG y temporales apuntando **todas** a subcarpetas del directorio que lo contiene, y reescribe la ruta del SDK que el asistente hardcodea (`AndroidSdkPathStore.xml`) más el symlink `$HOME/Android/Sdk` para los componentes que la ignoran.

Varables que se redirigen: `ANDROID_SDK_ROOT`, `ANDROID_HOME`, `ANDROID_USER_HOME`, `ANDROID_AVD_HOME`, `GRADLE_USER_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `TMPDIR`/`TEMP`/`TMP`, `STUDIO_PROPERTIES`, y `idea.config/system/plugins/log/cache` vía `studio.properties`.

## Verificación

```bash
bash tests/run-tests.sh   # 49 aserciones, todas verde
```

Estado de verificación: PASS ejecutado. Además, la instalación real se valida de forma periódica por un bot de humo (fuera del repo) que registra en `docs/04-fallos.md` qué falla y cómo se resolvió.

## Reproducibilidad

`git clone` + `./setup.sh --dest ...` sin flags extra: el setup deriva en runtime la ubicación del tar (resolviendo la URL estable oficial), todas las rutas de usuario (`[BASH_SOURCE]`, `$HOME`, `%h`) y no contiene nombres ni rutas de su autor. En `docs/03-entorno.md` está el entorno donde fue validado.

## Licencia

MIT — Porto en `LICENSE`.