# Estrategia de pruebas

## TL;DR

Cuatro suites en `tests/` (46 aserciones totales en estado verde): 3 de caja negra (setup, lanzador, uninstall) y 1 de caja blanca. Se ejecutan sin instalar nada y sin tocar el sistema real, usando `HOME` y directorios temporales falsos.

## Caja negra — comportamiento observable

En estas pruebas solo se inspecciona lo que produce el sistema, no el código interno.

| Suite | Qué verifica |
|---|---|
| `blackbox_setup.test.sh` | `setup.sh` termina con código 0, crea las 13 carpetas del árbol, genera `studio-portable.sh` (ejecutable), `studio.properties` y el estado `AndroidSdkPathStore.xml`; extrae `bin/studio.sh` desde un tar.gz mínimo de prueba. |
| `blackbox_launcher.test.sh` | Con un `bin/studio.sh` falso, el lanzador ejecuta el binario del destino correcto y las variables de entorno exportadas apuntan a `sdk/`, `avd/`, `.gradle/`, `studio.properties`. También crea el symlink `$HOME/Android/Sdk`. |
| `blackbox_uninstall.test.sh` | `uninstall.sh` elimina el destino completo, con `--keep-binaries` conserva `android-studio/` y `sdk/`, retira el symlink que apunta a este destino y respeta symlinks de otros destinos. |

## Caja blanca — contenido e invariantes

| Suite | Qué verifica |
|---|---|
| `whitebox_content.test.sh` | Los templates usan `idea.home.path` y `BASH_SOURCE` (rutas relativas, nada de usuarios con nombre fijo), el lanzador usa `ln -sfn` y `exec`, `setup.sh` es idempotente (mismo hash en dos corridas) y documenta sus opciones en `--help`. |

## Prueba de regresión contra producción

La lógica del template `src/studio-portable.sh.in` se comparó con el lanzador de la instalación real validada; el diff libre de comentarios es vacío. Contrato: cualquier cambio futuro debe conservar esa equivalencia.

## Correr

```bash
bash tests/run-tests.sh
```

Salida: líneas `ok`/`FAIL` por aserción y resumen por suite. Exit 0 solo si todas pasan.