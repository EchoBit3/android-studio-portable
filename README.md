# android-studio-portable

Android Studio autocontenido en un solo directorio: el IDE, el SDK, los emuladores (AVDs), Gradle, las cachés y la configuración viven dentro de la carpeta de instalación. Podés moverla, copiarla o borrarla entera sin dejar rastros (salvo un symlink `$HOME/Android/Sdk` que Android Studio necesita y que `uninstall.sh` retira).

## Requisitos

| Necesitás | Para qué | Cómo comprobarlo |
|---|---|---|
| Linux x86_64 con `bash` 4+ | todo | `bash --version` |
| `tar` | desempaquetar el IDE | `tar --version` |
| `curl` o `wget` | bajar el IDE y el SDK | `curl --version` |
| `sha256sum` (coreutils) | verificar la integridad de la descarga | `sha256sum --version` |
| `flock` (util-linux) | evitar dos actualizaciones a la vez | `flock --version` |
| **~10 GB libres** | IDE (~3 GB) + SDK + AVDs | `df -h "$HOME"` |
| `unzip` | solo si vas a usar el emulador | `unzip -v` |
| KVM (`/dev/kvm`) | solo para que el emulador acelere | `ls -l /dev/kvm` |

No hace falta `sudo`, ni Java, ni Gradle, ni Android Studio instalados: el IDE trae su propio runtime y todo se escribe en el directorio destino.

## Instalación

```bash
git clone https://github.com/EchoBit3/android-studio-portable.git
cd android-studio-portable
./setup.sh --dest "$HOME/AndroidStudio-Portable"
```

`setup.sh` resuelve la última versión estable en `developer.android.com/studio`, la descarga, verifica su sha256 y arma la estructura portable. Si ya tenés el tar descargado o querés fijar una versión, pasalo con `--tar`:

```bash
./setup.sh --dest "$HOME/AndroidStudio-Portable" --tar ~/Descargas/android-studio-linux.tar.gz
```

Opciones útiles de `setup.sh --help`: `--tar`, `--home` (otro `$HOME` para el symlink), `--no-symlink`. Si usás un tar propio, fijá el checksum esperado con `PORTABLE_IDE_SHA256=<sha256> ./setup.sh ...`.

## Verificar que quedó bien

```bash
# 1. el lanzador existe y es ejecutable
test -x "$HOME/AndroidStudio-Portable/studio-portable.sh" && echo "lanzador OK"

# 2. el symlink del SDK apunta al destino
readlink "$HOME/Android/Sdk"

# 3. abre el IDE (la primera vez tarda en inicializar)
"$HOME/AndroidStudio-Portable/studio-portable.sh"
```

Todo lo que el IDE escriba (configuración, cachés, AVDs, Gradle) queda dentro de `$HOME/AndroidStudio-Portable`.

## Uso diario

```bash
"$HOME/AndroidStudio-Portable/studio-portable.sh"               # abre el IDE
"$HOME/AndroidStudio-Portable/studio-portable.sh /ruta/proyecto" # abre un proyecto
PORTABLE_NO_UPDATE=1 "$HOME/AndroidStudio-Portable/studio-portable.sh"  # sin buscar actualizaciones
```

Si querés un atajo en el PATH:

```bash
mkdir -p "$HOME/bin"
ln -sfn "$HOME/AndroidStudio-Portable/studio-portable.sh" "$HOME/bin/studio"
```

## Emulador (opcional)

```bash
./install-emulator.sh --dest "$HOME/AndroidStudio-Portable" --avd Pixel_API_35
```

Instala `emulator`, `platform-tools` y una system image dentro del SDK portable, y crea el AVD en `avd/`. Si el SDK no tiene las cmdline-tools, las descarga de Google (requiere `unzip`; el script avisa antes de bajar nada si falta). Ver `./install-emulator.sh --help` para `--image`, `--device` y `--sdkmanager` (útil si ya tenés un `sdkmanager` local).

Después el emulador se lanza desde el IDE o con:

```bash
"$HOME/AndroidStudio-Portable/sdk/emulator/emulator" -avd Pixel_API_35
```

## Actualización

El lanzador revisa si hay una versión nueva de Android Studio y la instala si corresponde: descarga, verifica sha256 y hace un intercambio atómico con rollback si la versión nueva no arranca. Google es la fuente principal; `version.json` del repo es el respaldo si la página cambia de formato.

## Pruebas

```bash
bash tests/run-tests.sh
```

143 aserciones en 7 suites (caja negra y blanca). No usan red ni instalan nada: trabajan con `HOME` y destinos temporales falsos.

## Desinstalación

```bash
./uninstall.sh --dest "$HOME/AndroidStudio-Portable"
```

Retira el lanzador, la configuración, el symlink y el directorio. `--keep-binaries` conserva `android-studio/` y `sdk/` por si querés reinstalar rápido.

## Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| `Falta --dest <dir>` | olvidaste el destino: `./setup.sh --dest <dir>` |
| `Fallo al resolver la URL estable` | sin red, o Google cambió la página: bajá el tar y usá `--tar` |
| `El sha256 del IDE no coincide` | descarga corrupta o alterada: se descarta sola, reintentá; con `--tar` fijá `PORTABLE_IDE_SHA256` |
| `Falta unzip` al instalar el emulador | `sudo apt install unzip`, o pasá `--sdkmanager` |
| `command not found: flock` | falta util-linux: `sudo apt install util-linux` |
| El emulador no arranca o va lento | falta KVM: habilitá virtualización en la BIOS y revisá `ls -l /dev/kvm` |
| Quiero empezar de cero | `./uninstall.sh --dest <dir>` y volver a instalar |

## Documentación

[`docs/`](docs/) cubre diseño, pruebas, QA, privacidad y estándares. Licencia MIT.
