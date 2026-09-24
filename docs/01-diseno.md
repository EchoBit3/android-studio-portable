# Diseño — android-studio-portable

## TL;DR

`setup.sh` instala Android Studio autocontenido en un directorio: estructura, lanzador y configuración redirigida para que **todo** quede dentro de esa carpeta. `studio-portable.sh` deriva su ubicación en runtime, así puedes mover o copiar la carpeta donde sea.

## Decisión de ejecución

El lanzador que validamos en producción hoy es idéntico en lógica al template de este repo (verificado con diff en la fase de verificación). El repo no incluye binarios ni el tar.gz: el clon obtiene scripts reproducibles y descarga el tar.gz oficial al instalar.

## Estructura del repo

```
setup.sh                Instalador (dest, tar/url, home, symlink)
uninstall.sh            Reversa de setup.sh (conserva o borra binarios)
src/studio-portable.sh.in   Template del lanzador (sin rutas del operador)
src/studio.properties.in    Template de config JetBrains con rutas relativas
tests/                      Suites de caja negra y caja blanca
docs/                       Documentación y diagramas
```

## Cómo logra la portabilidad

- **Config JetBrains**: `studio.properties` redirige `idea.config/system/plugins/log/cache` a subcarpetas del directorio portable usando `${idea.home.path}` relativo (`src/studio.properties.in:1`).
- **SDK y herramientas**: `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `ANDROID_USER_HOME`, `ANDROID_AVD_HOME` y `GRADLE_USER_HOME` apuntan a directorios propios (`src/studio-portable.sh.in:5`).
- **XDG y temporales**: `XDG_CONFIG/CACHE/DATA_HOME`, `TMPDIR/TEMP/TMP` redirigen a la carpeta portable (`src/studio-portable.sh.in:8`).
- **Ruta del SDK que hardcodea el asistente**: el IDE persiste la ruta en `AndroidSdkPathStore.xml`; el lanzador la reescribe con la ruta real y **no** el default `~/Android/Sdk`. Además crea el symlink `$HOME/Android/Sdk -> BASE/sdk` para los componentes que la ignoran (`src/studio-portable.sh.in:15`).

## Supuestos y límites

- Sistema Linux (target Fedora/KDE), bash 5.x.
- El emulador necesita KVM; si el AVD se crea desde el IDE usa `ANDROID_AVD_HOME=BASE/avd`.
- Premium edge: algunos plugins de terceros pueden escribir fuera; el repo documenta las variables que el 99% respeta.