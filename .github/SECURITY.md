# Política de seguridad

## TL;DR

Este repo contiene scripts de shell que instalan Android Studio en una carpeta portátil. Si encontrás una vulnerabilidad, **no abras un issue público**: usá el botón **Report a vulnerability** de la pestaña *Security* (reporte privado). Si ese botón no está disponible, contactá al mantenedor por su perfil de GitHub.

## Alcance

| Dentro del alcance | Fuera de alcance |
|---|---|
| Scripts del repo: `setup.sh`, `uninstall.sh`, `src/`, `tests/` | Binario de Android Studio, SDK y componentes de Google (se descargan de la página oficial y se verifican con SHA-256) |
| Workflows de CI (`.github/workflows/`) | Fallos de la distro, del kernel o de KVM |
| Descarga, verificación y activación de actualizaciones | Problemas del emulador o del IDE que no involucren estos scripts |
| Escritura fuera del directorio destino (path traversal, symlinks) | Dependencias de terceros dentro del IDE |

## Cómo responde el diseño

- **Sin privilegios**: nada requiere `sudo`; el instalador solo escribe en el directorio `--dest` (más el symlink `~/Android/Sdk`, desactivable con `--no-symlink`).
- **Integridad de updates**: toda actualización se verifica con **SHA-256** contra el manifest antes de activarse; si falla, queda la versión anterior (swap atómico + rollback).
- **Sin secretos en el repo**: *secret scanning* con *push protection* activos en GitHub, más la aserción `whitebox_security` de la suite (`grep -r` de patrones de tokens/claves).
- **Análisis estático**: ShellCheck en cada push/PR (code scanning) y Dependabot para las acciones de CI.
- **La suite es offline**: las pruebas corren con `HOME` y tar.gz falsos en `/tmp`; no tocan la red ni el sistema real.

## Qué esperar al reportar

1. Confirmación de recepción por el mismo canal.
2. Evaluación de impacto y, si se confirma, corrección en una rama con PR (nunca directo a `main`) y atribución en el `CHANGELOG`.
3. Sin SLA formal de tiempos: es un proyecto personal; la respuesta llega por el canal usado en el reporte.

> Las versiones y sus notas están en [`CHANGELOG.md`](../CHANGELOG.md); los tags en la pestaña *Releases*.
