# Privacidad y transparencia

> Resumen en una línea: este proyecto **no recolecta datos personales**, no tiene telemetría propia, no pide ningún identificador y no se comunica por cuenta propia con ningún servicio.

## Qué es y qué no es

`android-studio-portable` es un conjunto de scripts que instalan Android Studio (software de Google) en una carpeta a elección del usuario. Los scripts **no** son una aplicación de red: no levantan servidores, no envían métricas, no registran uso.

## Qué se guarda y dónde

| Dato | Dónde se guarda | ¿Sale de la máquina? |
|---|---|---|
| Configuración del IDE de JetBrains | En tu carpeta portable (por defecto `<dest>/AndroidStudioConfig` etc.) | No |
| SDK, AVDs, Gradle, cachés | Subcarpetas de `<dest>` | No |
| Versión instalada | `<dest>/.studio-version` | No |
| Metadatos de actualización (caché 24 h) | `<dest>/.config/update-cache` | No (solo se avisa/escribe lo que ya se consultó) |
| Symlink `~/Android/Sdk` | Fuera del portable, apunta a tu `<dest>/sdk` | No (es local, 0 bytes) |

## Comunicaciones de red

El proyecto **solo** inicia conexiones salientes cuando lo pedís explícitamente:

1. **`setup.sh` sin `--tar`**: consulta `developer.android.com/studio` para conocer la URL de descarga vigente y baja el tar.gz **oficial de Google** (~1.5 GB). Los scripts no reenvían esa petición a ningún otro servidor.
2. **`setup.sh --tar <url>`**: descarga del servidor que **vos** indiqués.
3. **Actualización del IDE** (si está activa y hay red): consulta a Google; la metadata queda en caché local 24 h.

Ninguna de estas llamadas incluye datos personales: no se envía nombre de usuario, correo, ni contenido de proyectos. Se envía una cabecera de *User-Agent* genérica de navegador por compatibilidad con la página oficial.

## Lo que NO hace este proyecto

- ❌ No recopila estadísticas de uso ni errores.
- ❌ No pide registro, cuenta ni correo.
- ❌ No guarda cookies ni identificadores persistentes propios.
- ❌ No sube nada de tu código ni de tus proyectos.
- ❌ No ejecuta binarios desconocidos: solo extrae el tar.gz **oficial** de Google (validando además que no haya rutas peligrosas `../` o absolutas, ver `05-qa.md` S1).
- ❌ No instala software a nivel sistema (no usa `sudo`), con la única excepción funcional del symlink `~/Android/Sdk` (0 bytes, removible con `uninstall.sh`).

## El que se va, se va (derecho al olvido, versión simple)

Para **eliminar todo rastro** del proyecto en tu máquina:

```bash
bash uninstall.sh --dest "$HOME/AndroidStudio-Portable"   # retira la instalación y el symlink
git clone ... ; # o simplemente borrá la carpeta del repo clonado
```

Con `uninstall.sh`, el symlink `~/Android/Sdk` se retira **solo si apunta a tu carpeta portable** (respeta symlinks de otros proyectos, verificado en `blackbox_uninstall.test.sh`).

## Qué guardan Google y GitHub (y cómo lo limitamos)

- El **script** no recolecta datos tuyos. Android Studio y los servicios de Google tienen su propia política (política de datos de Google, acceso 2026-09-24) que no controla este proyecto.
- El **repo** vive en GitHub (EchoBit3/android-studio-portable). Tu uso de `git clone/git` está sujeto a la política de GitHub.
- Si clonás y solo corrés scripts, no se comparte nada de tu instalación con el mantenedor del repo ni con los servidores del repo (a excepción de la descarga oficial mencionada).

## Declaración de mínimo

Este proyecto apunta a cumplir con los principios de mínimo necesario y transparencia de la ley de protección de datos chilena (Ley 19.628 / Ley 21.719, ver `07-estandares.md`): al no tratar datos personales en ninguna operación, la superficie de riesgo es mínima por diseño. Se documenta esto como política, no como un "no-logs" vacío: la evidencia está en el código fuente (búsqueda de red) y en las suites de seguridad (`05-qa.md` S5).