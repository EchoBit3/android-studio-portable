# android-studio-portable

Android Studio autocontenido en un solo directorio: el IDE, el SDK, los emuladores (AVDs), Gradle, las cachés y la configuración viven dentro de la carpeta de instalación. Podés moverla, copiarla o borrarla entera sin dejar rastros (salvo un symlink opcional `$HOME/Android/Sdk` que el IDE necesita y `uninstall.sh` retira).

## Instalación

```bash
git clone https://github.com/EchoBit3/android-studio-portable.git
cd android-studio-portable
./setup.sh --dest "$HOME/AndroidStudio-Portable"
"$HOME/AndroidStudio-Portable/studio-portable.sh"
```

Requisitos: Linux con bash, tar y curl o wget (más `flock`). No se necesita sudo ni Java/Gradle previos: el IDE trae su propio runtime.

## Emulador (opcional)

```bash
./install-emulator.sh --dest "$HOME/AndroidStudio-Portable" --avd Pixel_API_35
```

Instala `emulator`, `platform-tools` y una system image dentro del SDK portable, y crea el AVD en `avd/`. Si faltan las cmdline-tools, las descarga de Google (requiere `unzip`). Ver `./install-emulator.sh --help` para `--image`, `--device` y `--sdkmanager`. Para usar el emulador hace falta KVM.

## Actualización

El lanzador revisa automáticamente si hay una versión nueva de Android Studio y la instala si corresponde: descarga, verifica sha256 y hace un intercambio atómico con rollback.

## Pruebas

```bash
bash tests/run-tests.sh
```

132 aserciones en 7 suites (caja negra y blanca), sin red ni instalación.

## Desinstalación

```bash
./uninstall.sh --dest "$HOME/AndroidStudio-Portable"
```

## Documentación

[`docs/`](docs/) cubre diseño, pruebas, QA, privacidad y estándares. Licencia MIT.
