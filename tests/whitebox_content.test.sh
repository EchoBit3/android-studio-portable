#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SAVED_HOME="$HOME"
FAKE_HOME="$TMP_ROOT/home"
FAKE_DEST="$TMP_ROOT/go"
mkdir -p "$FAKE_HOME"

setup_script="$REPO_DIR/setup.sh"
launcher_template="$REPO_DIR/src/studio-portable.sh.in"
properties_template="$REPO_DIR/src/studio.properties.in"

# Construimos un tar.gz mínimo que imite la distribución de Google
tar_root="$TMP_ROOT/mktar"
mkdir -p "$tar_root/android-studio/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tar_root/android-studio/bin/studio.sh"
chmod +x "$tar_root/android-studio/bin/studio.sh"
FAKE_TAR="$TMP_ROOT/android-studio-fake.tar.gz"
tar -C "$tar_root" -czf "$FAKE_TAR" android-studio

printf '== Caja blanca: contenido e invariantes ==\n'

# 1. El template de properties usa rutas relativas al IDE, nunca del usuario
assert_true "grep -q 'idea.home.path' '$properties_template'" \
    "studio.properties usa idea.home.path para rutas relativas"
assert_true "! grep -q '/home/' '$properties_template'" \
    "el template de properties no contiene rutas absolutas"

# 2. El template del lanzador deriva su base en runtime, sin hardcode
assert_true "grep -q 'BASH_SOURCE' '$launcher_template'" \
    "el lanzador deriva su ubicación con BASH_SOURCE"
assert_true "! grep -q 'usuario' '$launcher_template'" \
    "el lanzador no contiene el nombre de usuario del operador"
assert_true "grep -q 'ln -sfn' '$launcher_template'" \
    "el lanzador crea el symlink idempotente con ln -sfn"
assert_true "grep -q 'exec ' '$launcher_template'" \
    "el lanzador delega en el studio.sh del destino con exec"

# 3. setup.sh es idempotente: correrlo dos veces no cambia el resultado
bash "$setup_script" --dest "$FAKE_DEST" --tar "$FAKE_TAR" \
    --home "$FAKE_HOME" --no-symlink >/dev/null 2>&1
before="$(find "$FAKE_DEST" -type f -o -type l | sort | xargs sha256sum 2>/dev/null)"

bash "$setup_script" --dest "$FAKE_DEST" --tar "$FAKE_TAR" \
    --home "$FAKE_HOME" --no-symlink >/dev/null 2>&1
after="$(find "$FAKE_DEST" -type f -o -type l | sort | xargs sha256sum 2>/dev/null)"

assert_eq "$after" "$before" "setup.sh es idempotente (mismo hash en segunda ejecución)"

# 4. setup.sh expone bien sus opciones
assert_true "bash '$setup_script' --help 2>&1 | grep -q -- '--dest'" \
    "setup.sh documenta --dest en --help"
assert_true "bash '$setup_script' --help 2>&1 | grep -q -- '--tar'" \
    "setup.sh documenta --tar en --help"

# 5. setup.sh resuelve la URL estable oficial sin hardcodear una versión
assert_true "grep -q 'stable_url()' '$REPO_DIR/src/lib-portable.sh'" \
    "lib-portable define la resolución de la URL estable"
assert_true "grep -q 'developer.android.com/studio' '$REPO_DIR/src/lib-portable.sh'" \
    "stable_url consulta la página oficial"
assert_true "! grep -qE 'ide-zips/[0-9]+\.[0-9]+' '$REPO_DIR/src/lib-portable.sh'" \
    "stable_url no fija ningún número de versión"

# 6. El lanzador integra la lógica de actualización sin convertirse en daemon
assert_true "grep -q 'check_update' '$launcher_template'" \
    "el lanzador invoca la comprobación de actualización"
assert_true "grep -q 'lib-portable.sh' '$launcher_template'" \
    "el lanzador delega en la librería instalada"
assert_true "grep -q 'PORTABLE_NO_UPDATE' '$launcher_template'" \
    "el lanzador expone la variable de escape para entornos sin red"
assert_true "grep -q 'rollback' '$launcher_template'" \
    "el lanzador restaura la versión anterior si la nueva no arranca"
assert_true "grep -q 'update_ide' '$REPO_DIR/src/lib-portable.sh'" \
    "lib-portable implementa la descarga y el swap atómico"

# 7. setup.sh despliega lib-portable.sh y registra la versión instalada
assert_true "grep -q 'lib-portable.sh' '$setup_script'" \
    "setup.sh despliega la librería portable en el destino"
assert_true "grep -q 'write_version' '$setup_script'" \
    "setup.sh registra la versión instalada"

# 8. Existe version.json como respaldo configurable, sin fijar versión en código
assert_file_exists "$REPO_DIR/version.json" "existe el manifest de respaldo version.json"
assert_true "grep -q '\"version\"' '$REPO_DIR/version.json'" \
    "version.json declara la versión vigente"

HOME="$SAVED_HOME"

if summarize; then
    exit 0
else
    exit 1
fi