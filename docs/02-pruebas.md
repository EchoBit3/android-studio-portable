# Estrategia de pruebas

## TL;DR

Seis suites en `tests/` (101 aserciones totales en estado verde): 4 de caja negra (setup, lanzador, uninstall, update) y 2 de caja blanca (contenido e invariantes, seguridad). Se ejecutan sin instalar nada y sin tocar el sistema real, usando `HOME` y directorios temporales falsos.

```bash
bash tests/run-tests.sh
```

Salida: líneas `ok`/`FAIL` por aserción y resumen por suite. Exit 0 solo si todas pasan. En CI (GitHub Actions) corre la misma batería.

## Caja negra — comportamiento observable

En estas pruebas solo se inspecciona lo que produce el sistema, no el código interno.

| Suite | Aserciones | Qué verifica |
|---|---|---|
| `blackbox_setup.test.sh` | 26 | `setup.sh` termina con código 0, crea las 13 carpetas del árbol, genera `studio-portable.sh` (ejecutable), `studio.properties` y el estado `AndroidSdkPathStore.xml`; extrae `bin/studio.sh` desde un tar.gz mínimo de prueba. **Casos hostiles**: rechaza tar con rutas `../` (no escribe fuera del destino) y con rutas absolutas (no extrae nada); falla sin `--dest` con código 1 y documenta `--dest` en la ayuda. |
| `blackbox_launcher.test.sh` | 11 | Con un `bin/studio.sh` falso, el lanzador ejecuta el binario del destino correcto y las variables de entorno exportadas apuntan a `sdk/`, `avd/`, `.gradle/`, `studio.properties`. También crea el symlink `$HOME/Android/Sdk`. |
| `blackbox_uninstall.test.sh` | 10 | `uninstall.sh` elimina el destino completo, con `--keep-binaries` conserva `android-studio/` y `sdk/`, retira el symlink que apunta a este destino, respeta symlinks de otros destinos, falla sin `--dest` con código 1 y `--help` documenta `--keep-binaries` y `--dest`. |
| `blackbox_update.test.sh` | 19 | El update híbrido (página oficial + `version.json`) resuelve url+sha256+versión; verifica sha256 antes de activar (update con sha inválido rechazado, versión intacta); rollback atómico restaura `.prev`; degradación controlada sin red/curl/flock. |

## Caja blanca — contenido e invariantes

| Suite | Aserciones | Qué verifica |
|---|---|---|
| `whitebox_content.test.sh` | 21 | Los templates usan `idea.home.path` y `BASH_SOURCE` (rutas relativas, nada de usuarios con nombre fijo), el lanzador usa `ln -sfn` y `exec`, `setup.sh` es idempotente (mismo hash en dos corridas) y documenta sus opciones en `--help`; `stable_url` no fija versión alguna. |
| `whitebox_security.test.sh` | 14 | Dependabot rastrea `github-actions`; `code-scan.yml` usa ShellCheck con `security-events: write`; `ci.yml` corre `tests/run-tests.sh`; `setup.sh` extrae con `--no-same-owner` y valida el tar (`tar -tzf`); `sha256sum` presente en lib; sin tokens ni claves en el árbol (grep); `version.json` tiene versión numérica. |

## Prueba de regresión contra producción

La lógica del template `src/studio-portable.sh.in` se comparó con el lanzador de la instalación real validada; el diff libre de comentarios es vacío. Contrato: cualquier cambio futuro debe conservar esa equivalencia (ver `05-qa.md` M1).

## Composición de la suite

`tests/run-tests.sh` ejecuta las seis suites en orden y agrega el resultado. El conteo global (101) se mantiene actualizado en `README.md` y `05-qa.md`.