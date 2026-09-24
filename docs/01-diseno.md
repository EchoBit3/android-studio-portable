# ¿Cómo hace este repo para que Android Studio sea portable?

## TL;DR

`setup.sh` instala Android Studio autocontenido en un directorio: estructura, lanzador y configuración redirigida para que **todo** quede dentro de esa carpeta. `studio-portable.sh` deriva su ubicación en runtime, así puedes mover o copiar la carpeta donde sea.

> Para el público no técnico, ver `00-intro.md` (qué es Android Studio y qué hace distinto este port, con FAQ). Este documento explica decisiones técnicas y sus motivos.

## Qué es Android Studio (un minuto)

Android Studio es el IDE oficial de Google para desarrollo de Android. Es una aplicación pesada que **asume** ciertos lugares estándar en el sistema del usuario para guardar su estado: configuración (`~/.config/Google/...`), cachés (`~/.cache`), SDK (`~/Android/Sdk`), emuladores (`~/.android`), Gradle (`~/.gradle`), temporales (`/tmp`). En una instalación normal, esos datos quedan dispersos y quedan "pegados" a una máquina.

Este proyecto existe porque esas **ubicaciones son variables de entorno** que el IDE y las herramientas de Android respetan: apuntándolas todas adentro de una carpeta, el IDE se vuelve portable sin modificar sus binarios.

## Decisión de ejecución

El lanzador que validamos en producción hoy es idéntico en lógica al template de este repo (verificado con diff en la fase de verificación). El repo no incluye binarios ni el tar.gz: el clon obtiene scripts reproducibles y descarga el tar.gz oficial al instalar.

**Por qué no commiteamos binarios**: el tar.gz de Android Studio pesa ~1.5 GB y cambia en cada release. Mantener binarios en git rompería la reproducibilidad (git no está hecho para eso) y duplicaría la descarga sin valor. El repo queda pequeño, revisable y portable por diseño.

## Estructura del repo

```
setup.sh                Instalador (dest, tar/url, home, symlink)
uninstall.sh            Reversa de setup.sh (conserva o borra binarios)
src/studio-portable.sh.in   Template del lanzador (sin rutas del operador)
src/studio.properties.in    Template de config JetBrains con rutas relativas
src/lib-portable.sh         Librería reutilizable (resolución de versión, update)
tests/                      Suites de caja negra y caja blanca (101 aserciones)
docs/                       Documentación y diagramas
.github/                    CI, code scanning (ShellCheck), Dependabot
VERSION                     Versión SemVer del repo
```

## Cómo logra la portabilidad

Cinco mecanismos, cada uno elegido porque el comportamiento del IDE lo exige:

1. **Config JetBrains** (`src/studio.properties.in`): redirige `idea.config/system/plugins/log/cache` a subcarpetas del directorio portable usando `${idea.home.path}` relativo (`src/studio.properties.in:1`).
2. **SDK y herramientas** (`src/studio-portable.sh.in:5`): `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `ANDROID_USER_HOME`, `ANDROID_AVD_HOME` y `GRADLE_USER_HOME` apuntan a directorios propios.
3. **XDG y temporales** (`src/studio-portable.sh.in:8`): `XDG_CONFIG/CACHE/DATA_HOME`, `TMPDIR/TEMP/TMP` redirigen a la carpeta portable.
4. **Ruta del SDK que hardcodea el asistente**: el IDE persiste la ruta en `AndroidSdkPathStore.xml`; el lanzador la reescribe con la ruta real y **no** el default `~/Android/Sdk`.
5. **Symlink `$HOME/Android/Sdk`**: algunos componentes de Google solo saben buscar el SDK ahí; se crea `ln -sfn` idempotente y `uninstall.sh` lo retira solo si apunta a este destino.

### Por qué el symlink + el XML (la decisión incómoda)

Android Studio tiene **dos caminos** para resolver el SDK y **ninguno respeta el 100 % de las variables**:

- El asistente de configuración y varios componentes **persisten** la ruta en `AndroidSdkPathStore.xml` (no la derivan de `ANDROID_HOME`).
- Otras herramientas buscan **directamente** en `~/Android/Sdk`.

El lanzador ataca ambos frentes: reescribe el XML **y** crea el symlink. Es la única forma probada de portabilidad real; el fallo original y su solución están en `docs/04-fallos.md` (F1). El symlink es un compromiso: un único archivo de 0 bytes fuera del directorio, documentado y reversible con `uninstall.sh`.

## Update y verificaciones de integridad

- La resolución de versión estable (`stable_url`) no fija versión en el repo: consulta la página oficial en runtime y extrae la URL vigente.
- El update híbrido cruza la página oficial con `version.json` (espejo) y valida **sha256** del tar descargado antes de activarlo. Si algo falla, el árbol anterior queda intacto (rollback atómico). Ver `05-qa.md` F9/F10, S3/S4.

## Supuestos y límites

- Sistema Linux (target Fedora/KDE), bash 5.x.
- El emulador necesita KVM; si el AVD se crea desde el IDE usa `ANDROID_AVD_HOME=BASE/avd`.
- Premium edge: algunos plugins de terceros pueden escribir fuera; el repo documenta las variables que el 99 % respeta.
- El repositorio sigue ISO/IEC/IEEE 12207 (ciclo de vida) y documenta calidad ISO/IEC 25010, seguridad ISO/IEC 27001/27002 y normativa chilena de datos — ver `07-estandares.md`.

## Trade-offs (decisiones incómodas, asumidas)

| Decisión | Lo que ganás | Lo que pagás |
|---|---|---|
| Symlink `$HOME/Android/Sdk` | Compatibilidad total: componentes de Google que solo buscan ahí | Un archivo de 0 bytes fuera del directorio (documentado, reversible) |
| Sin binarios en el repo | Repo pequeño, reproducible, revisable en diffs | Necesitás red en el primer `setup.sh` (~1.5 GB) |
| `--no-same-owner` en la extracción | Seguridad: nada escrito como root/otro dueño | Permisos de propietario del tar no se preservan |
| Update con manifest + sha256 | Integridad verificada antes de activar | Una descarga fallida se reintenta; nunca se rompe la instalación vigente |

> Over to you: ¿cambiarías alguno de estos trade-offs o agregarías otro?