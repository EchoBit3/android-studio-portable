# Changelog

## 2026-09-24

- Repo reproducible `android-studio-portable`: setup.sh, uninstall.sh, templates en src/, 46 aserciones de caja negra y blanca en tests/.
- Lógica del lanzador idéntica a la instalación portable validada en producción.
- Documentación: README, docs/01-diseno, docs/02-pruebas, docs/03-entorno (specs reales del equipo de validación), docs/04-fallos (4 fallos resueltos + registro automático del bot), diagrama Mermaid en docs/assets/.
- No incluye binarios ni tar.gz (ver .gitignore).

## 2026-09-24 (reproducibilidad total)

- `setup.sh`: sin `--tar`, resuelve la última versión estable oficial desde developer.android.com/studio vía `stable_url()` y la descarga con curl — clonar + `./setup.sh --dest ...` alcanza, sin flags ni red preconfigurada.
- Sin números de versión fijos en el repo: el parseo extrae la URL vigente en runtime (verificado en vivo: `2026.1.4.8`).
- Suite ampliada a 49 aserciones (nuevos invariantes: `stable_url` existe, consulta la página oficial, no fija versión).
- README con sección de Reproducibilidad.