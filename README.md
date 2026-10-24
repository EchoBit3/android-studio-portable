# android-studio-portable

Android Studio autocontenido en un solo directorio. El IDE, SDK, emuladores, Gradle, caches y configuracion viven dentro de la carpeta de instalacion.

## Instalacion

```bash
git clone https://github.com/EchoBit3/android-studio-portable.git
cd android-studio-portable
./setup.sh --dest "$HOME/AndroidStudio-Portable"
"$HOME/AndroidStudio-Portable/studio-portable.sh"
```

Requisitos: Linux con bash, tar y curl o wget. No se necesita sudo ni Java previo.

## Emulador (opcional)

```bash
./install-emulator.sh /ruta/a/AndroidStudio-Portable
```

## Actualizacion

El lanzador revisa automaticamente si hay una version nueva de Android Studio y la instala si corresponde.

## Pruebas

```bash
bash tests/run-tests.sh
```

## Desinstalacion

```bash
./uninstall.sh --dest "$HOME/AndroidStudio-Portable"
```