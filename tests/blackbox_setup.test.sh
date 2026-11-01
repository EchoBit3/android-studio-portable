#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SAVED_HOME="$HOME"
SAVED_PWD="$PWD"

FAKE_HOME="$TMP_ROOT/home"
FAKE_DEST="$TMP_ROOT/go"
mkdir -p "$FAKE_HOME" "$FAKE_DEST"

HOME="$FAKE_HOME"
FAKE_TAR="$TMP_ROOT/android-studio-fake.tar.gz"
FAKE_STUDIO_BIN="$FAKE_DEST/android-studio/bin"

# Construimos un tar.gz mínimo que imite la distribución de Google
tar_root="$TMP_ROOT/mktar"
mkdir -p "$tar_root/android-studio/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tar_root/android-studio/bin/studio.sh"
chmod +x "$tar_root/android-studio/bin/studio.sh"
tar -C "$tar_root" -czf "$FAKE_TAR" android-studio

setup_script="$REPO_DIR/setup.sh"
launcher_source="$REPO_DIR/src/studio-portable.sh.in"
properties_source="$REPO_DIR/src/studio.properties.in"

printf '== Caja negra: setup.sh ==\n'

# 1. Los templates existen en el repo (fuente de generación)
assert_file_exists "$launcher_source" "template de lanzador existe en src/"
assert_file_exists "$properties_source" "template de studio.properties existe en src/"

# 2. setup.sh genera la estructura de carpetas autocontenida
bash "$setup_script" --dest "$FAKE_DEST" --tar "$FAKE_TAR" --home "$FAKE_HOME" --no-symlink >"$TMP_ROOT/setup.log" 2>&1
setup_rc=$?
assert_eq "$setup_rc" "0" "setup.sh termina con código 0"

for d in sdk avd .gradle .android .config .cache .local/share tmp \
         AndroidStudioConfig AndroidStudioSystem AndroidStudioPlugins AndroidStudioLogs; do
    assert_true "[ -d '$FAKE_DEST/$d' ]" "setup.sh crea $d/ en el destino"
done

# 3. setup.sh genera el lanzador y studio.properties en el destino
assert_file_exists "$FAKE_DEST/studio-portable.sh" "genera studio-portable.sh"
assert_file_exists "$FAKE_DEST/studio.properties" "genera studio.properties"
assert_file_exists "$FAKE_DEST/AndroidStudioConfig/options/AndroidSdkPathStore.xml" "genera el estado del SDK"

# 4. El lanzador generado es ejecutable
assert_true "[ -x '$FAKE_DEST/studio-portable.sh' ]" "studio-portable.sh tiene permiso de ejecución"

# 5. Sin binarios incluidos por setup: se usa el tar.gz provisto
assert_true "[ -f '$FAKE_STUDIO_BIN/studio.sh' ]" "setup.sh extrae android-studio/bin/studio.sh del tar"

HOME="$SAVED_HOME"
cd "$SAVED_PWD" || exit 1

# 6. Rechaza tar.gz con path traversal (../) antes de extraer
TRAV_ROOT="$TMP_ROOT/trav"
mkdir -p "$TRAV_ROOT"
printf 'x' > "$TRAV_ROOT/fuera.txt"
tar -C "$TRAV_ROOT" --transform='s|^|../|' -czf "$TMP_ROOT/trav-bad.tar.gz" fuera.txt 2>/dev/null
TRAV_DEST="$TMP_ROOT/trav-dest"
mkdir -p "$TRAV_DEST"
bash "$setup_script" --dest "$TRAV_DEST" --tar "$TMP_ROOT/trav-bad.tar.gz" --home "$FAKE_HOME" --no-symlink >"$TMP_ROOT/trav.log" 2>&1
trav_rc=$?
assert_true "[ '$trav_rc' -ne 0 ]" "setup.sh rechaza un tar.gz con rutas ../"
assert_true "[ ! -e '$TMP_ROOT/fuera.txt' ]" "el tar hostil no escribió fuera del destino"

# 7. Rechaza tar.gz con rutas absolutas
tar -C "$TRAV_ROOT" --transform='s|^|/|' -czf "$TMP_ROOT/abs-bad.tar.gz" fuera.txt 2>/dev/null
ABS_DEST="$TMP_ROOT/abs-dest"
mkdir -p "$ABS_DEST"
bash "$setup_script" --dest "$ABS_DEST" --tar "$TMP_ROOT/abs-bad.tar.gz" --home "$FAKE_HOME" --no-symlink >"$TMP_ROOT/abs.log" 2>&1
abs_rc=$?
assert_true "[ '$abs_rc' -ne 0 ]" "setup.sh rechaza un tar.gz con rutas absolutas"
assert_true "[ ! -e '$ABS_DEST/fuera.txt' ]" "el tar hostil absoluto no se extrajo dentro del destino"

# 8. setup.sh falla sin --dest y documenta el flag
bash "$setup_script" >"$TMP_ROOT/nodest.log" 2>&1
assert_eq "$?" "1" "setup.sh sin --dest termina con código 1"
assert_true "grep -q -- '--dest' '$TMP_ROOT/nodest.log'" "setup.sh sin --dest imprime la ayuda con --dest"

if summarize; then
    exit 0
else
    exit 1
fi