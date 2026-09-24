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
cd "$SAVED_PWD"

if summarize; then
    exit 0
else
    exit 1
fi