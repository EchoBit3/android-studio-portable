# Changelog

Versión actual: `0.1.1` (ver `VERSION`).

## 2026-09-24 — v0.1.1 (fix loop de update en instalaciones patch)

- **Fix `installed_version`**: `.studio-version` es ahora la fuente autoritativa de la versión instalada con fallback a `product-info.json`. Un patch release (ej. `2026.1.4.8`) no cambia `dataDirectoryName` y antes `check_update` re-descargaba el IDE en cada caché vencida (loop 24h).
- **Fix `rollback`**: recalcula la versión desde el payload restaurado de `.prev` sin la redirección prematura que creaba `.studio-version` vacío.
- **Pruebas**: nueva aserción (suite `blackbox_update` 19→20, total 101→102) que prioriza `.studio-version` sobre `product-info.json`.
- **CI**: Dependabot bump `actions/checkout` 4→7 (PR #4); ramas `feat/auto-update` y `feat/calidad-y-seguridad` retiradas tras absorción en `main`.
- Suites vigentes: blackbox_setup 26 · blackbox_launcher 11 · blackbox_uninstall 10 · blackbox_update 20 · whitebox_content 21 · whitebox_security 14 = **102**.

## 2026-09-24 — v0.1.0 (calidad, seguridad y documentación)

- **Documentación rediseñada para públicos técnico y no técnico**: `00-intro.md` (nuevo), `README.md` reescrito, `01-diseno.md` ampliado con decisiones y por qué, `05-qa.md` (checklist QA exhaustivo por atributos ISO/IEC 25010 con huecos declarados), `06-privacidad.md` (nuevo), `07-estandares.md` (nuevo, leyes Chile + ISO con citas oficiales).
- **Mermaid renderizable en GitHub**: se reemplazó `docs/assets/portable-flujo.mmd` por `docs/assets/portable-flujo.md` con fence ```mermaid``` (GitHub no renderiza `.mmd`).
- **Pruebas ampliadas a 101 aserciones** en 6 suites: nueva suite `whitebox_security.test.sh` (14) y casos hostiles de tar (`../`, rutas absolutas), fallo sin `--dest`, opciones de `--help` en setup/uninstall.
- **Seguridad de GitHub**: Dependabot (`github-actions`, semanal), code scanning ShellCheck→SARIF en `code-scan.yml`, vulnerability alerts y automated security fixes habilitados vía API, secret scanning + push protection activos. ShellCheck local limpio (`-S warning`).
- **Versionado**: `VERSION` (SemVer) y política documentada en `07-estandares.md`.
- Suites vigentes: blackbox_setup 26 · blackbox_launcher 11 · blackbox_uninstall 10 · blackbox_update 19 · whitebox_content 21 · whitebox_security 14 = **101**.

## 2026-09-24

- Repo reproducible `android-studio-portable`: setup.sh, uninstall.sh, templates en src/, 101 aserciones de caja negra y blanca en tests/.
- Lógica del lanzador idéntica a la instalación portable validada en producción.
- Documentación: README, docs/01-diseno, docs/02-pruebas, docs/03-entorno (specs reales del equipo de validación), docs/04-fallos (fallos resueltos + registro automático del bot), diagrama Mermaid en docs/assets/.
- No incluye binarios ni tar.gz (ver .gitignore).

## 2026-09-24 (reproducibilidad total)

- `setup.sh`: sin `--tar`, resuelve la última versión estable oficial desde developer.android.com/studio vía `stable_url()` y la descarga con curl — clonar + `./setup.sh --dest ...` alcanza, sin flags ni red preconfigurada.
- Sin números de versión fijos en el repo: el parseo extrae la URL vigente en runtime (verificado en vivo: `2026.1.4.8`).
- Suite ampliada a 101 aserciones (nuevos invariantes: `stable_url` existe, consulta la página oficial, no fija versión).
- README con sección de Reproducibilidad.