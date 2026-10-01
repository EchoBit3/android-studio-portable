# Changelog

Versión actual: `0.2.3` (ver `VERSION`).

## 2026-10-01 — v0.2.3 (lanzador vía symlink + nota de duración del update)

- **Lanzador invocable vía symlink**: `BASE` se deriva con `readlink -f "${BASH_SOURCE[0]}"` (mismo patrón que `setup.sh`) — un atajo `~/bin/studio -> …/studio-portable.sh` ahora resuelve al destino real en vez de tomar `~/bin` como base. Antes el atajo quedaba roto.
- **Pruebas**: `blackbox_launcher` invoca el lanzador a través de un symlink y verifica `BASE` (14→16); `whitebox_content` exige `readlink -f` en el template (24→25). Total **111**.
- **Docs**: README y FAQ `00-intro` explican que la primera actualización descarga ~1,5 GB y puede tardar varios minutos (se retoma si se interrumpe; no es un bloqueo). Conteos 108→111 en `01-diseno`/`02-pruebas`/`03-entorno`; D4 de `05-qa` cubre la invocación vía symlink.
- Suites vigentes: blackbox_setup 26 · blackbox_launcher 16 · blackbox_uninstall 10 · blackbox_update 20 · whitebox_content 25 · whitebox_security 14 = **111**.

## 2026-10-01 — v0.2.2 (seguridad en español + alerta SC2034)

- **`.github/SECURITY.md`**: política de seguridad en español — alcance (scripts/CI) y fuera de alcance (binario de Google), garantías del diseño (sin sudo, SHA-256 en updates, secret scanning, suite offline) y canal de reporte privado. La pestaña Security de GitHub ahora muestra esta política en español en lugar del texto genérico en inglés.
- **Alerta code scanning cerrada**: `tests/blackbox_launcher.test.sh` declara `# shellcheck disable=SC2034` en `out_fb` (se consume vía `eval` en `assert_true`, uso que ShellCheck no ve) — la alerta SC2034 abierta no volverá a generarse. ShellCheck local (imagen oficial, `-s bash -S warning`): rc=0.
- **README**: bullet con enlace a la política de seguridad.
- No cambia el conteo: **108 aserciones** en 6 suites.

## 2026-10-01 — v0.2.1 (multi-distro)

- **CI con matriz de distros**: además de `ubuntu-latest`, la suite corre en contenedores de **CachyOS** (imagen oficial `cachyos/cachyos`), **Arch**, **Fedora** y **Debian** (`fail-fast: false` para que cada familia informe por separado).
- **Invariante multi-distro**: `whitebox_content` verifica que el código ejecutable (`setup.sh`, `uninstall.sh`, `src/`) no referencie gestores de paquetes (`dnf`, `apt-get`, `pacman`, `zypper`, `rpm`, `emerge`, `flatpak`) — 23→24 aserciones. Total **108**.
- **Docs**: README y `01-diseno`/`02-pruebas`/`03-entorno`/`05-qa` pasan de "validado en Fedora" a matriz multi-distro con evidencia (CachyOS validado en contenedor: 108/108 PASS).
- **Aserción de secretos sin `git`**: `whitebox_security` usa `grep -r` nativo (excluye `.git` y `tests/`) en vez de `git grep` condicional — las 5 distros corren **108/108** sin instalar nada (antes: 107 en Arch/Fedora/Debian por la aserción condicionada a `git`).
- Suites vigentes: blackbox_setup 26 · blackbox_launcher 14 · blackbox_uninstall 10 · blackbox_update 20 · whitebox_content 24 · whitebox_security 14 = **108**.

## 2026-09-24 — v0.2.0 (launcher nativo con fallback)

- **Launcher nativo**: `studio-portable.sh` ahora prefiere `bin/studio` (ELF, launcher nativo recomendado por JetBrains desde la 2024.2) y cae a `bin/studio.sh` (script legacy) solo si el nativo no existe. Motivo: arranque más rápido, mejor integración con Wayland y desaparición del aviso *"Consider switching to a native launcher"*.
- **Preflight del update**: `update_ide` acepta el árbol si tiene `bin/studio` **o** `bin/studio.sh` ejecutable; `setup.sh` (idempotencia) mismo criterio.
- **Pruebas**: `blackbox_launcher` agrega preferencia nativa (`LAUNCHER=native`) y fallback (`LAUNCHER=script`) 11→14; `whitebox_content` agrega invariantes de resolución de launcher 21→23. Total **107** aserciones.
- **Docs**: README, `02-pruebas.md`, `05-qa.md` (F3/F4b, S4, E3) y diagrama `portable-flujo.md` actualizados con el launcher nativo y sus citas oficiales (SUPPORT-A-56 y guía CLI de JetBrains).
- Suites vigentes: blackbox_setup 26 · blackbox_launcher 14 · blackbox_uninstall 10 · blackbox_update 20 · whitebox_content 23 · whitebox_security 14 = **107**.

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