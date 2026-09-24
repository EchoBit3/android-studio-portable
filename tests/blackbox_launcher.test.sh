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

# Construimos un tar.gz falso con android-studio/bin/studio.sh para que setup.sh
# extraiga el binario y genere el lanzador en el destino.
FAKE_TAR_BASE="$TMP_ROOT/mktar"
mkdir -p "$FAKE_TAR_BASE/android-studio/bin"
cat > "$FAKE_TAR_BASE/android-studio/bin/studio.sh" <<'EOF'
#!/usr/bin/env bash
printf 'IDE_HOME=%s\n' "$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
env | grep -E '^(ANDROID_SDK_ROOT|ANDROID_HOME|ANDROID_USER_HOME|ANDROID_AVD_HOME|GRADLE_USER_HOME|XDG_CONFIG_HOME|XDG_CACHE_HOME|XDG_DATA_HOME|TMPDIR|STUDIO_PROPERTIES)=' | sort
exit 0
EOF
chmod +x "$FAKE_TAR_BASE/android-studio/bin/studio.sh"
FAKE_TAR="$TMP_ROOT/android-studio-fake.tar.gz"
tar -C "$FAKE_TAR_BASE" -czf "$FAKE_TAR" android-studio

# Instalamos con setup.sh para obtener el lanzador apuntando al destino falso
bash "$REPO_DIR/setup.sh" --dest "$FAKE_DEST" --tar "$FAKE_TAR" --home "$FAKE_HOME" >/dev/null 2>&1

printf '== Caja negra: studio-portable.sh (lanzador) ==\n'

# 1. El lanzador deriva BASE en runtime y exporta las variables al subproceso
out="$(HOME="$FAKE_HOME" PORTABLE_NO_UPDATE=1 bash "$FAKE_DEST/studio-portable.sh" 2>&1)"
rc=$?
assert_eq "$rc" "0" "el lanzador termina con código 0 cuando el binario existe"

assert_true "printf '%s' \"\$out\" | grep -q 'IDE_HOME=$FAKE_DEST/android-studio'" \
    "el lanzador ejecuta el studio.sh del destino real"

assert_true "printf '%s' \"\$out\" | grep -q '^ANDROID_SDK_ROOT=$FAKE_DEST/sdk\$'" \
    "ANDROID_SDK_ROOT apunta a sdk/ del destino"
assert_true "printf '%s' \"\$out\" | grep -q '^ANDROID_HOME=$FAKE_DEST/sdk\$'" \
    "ANDROID_HOME apunta a sdk/ del destino"
assert_true "printf '%s' \"\$out\" | grep -q '^ANDROID_AVD_HOME=$FAKE_DEST/avd\$'" \
    "ANDROID_AVD_HOME apunta a avd/ del destino"
assert_true "printf '%s' \"\$out\" | grep -q '^GRADLE_USER_HOME=$FAKE_DEST/.gradle\$'" \
    "GRADLE_USER_HOME apunta a .gradle/ del destino"
assert_true "printf '%s' \"\$out\" | grep -q '^STUDIO_PROPERTIES=$FAKE_DEST/studio.properties\$'" \
    "STUDIO_PROPERTIES apunta al properties del destino"

# 2. El lanzador actualiza AndroidSdkPathStore con la ruta del destino
store="$FAKE_DEST/AndroidStudioConfig/options/AndroidSdkPathStore.xml"
assert_true "[ -f '$store' ]" "el lanzador genera el store de la ruta del SDK"
assert_true "grep -q 'value=\"$FAKE_DEST/sdk\"' '$store'" \
    "el store contiene la ruta absoluta del SDK del destino"

# 3. El lanzador no hardcodea el usuario ni rutas del repo
assert_true "! grep -q 'usuario' '$store'" "el store no contiene rutas del operador"

HOME="$SAVED_HOME"

# 4. El lanzador genera el symlink $HOME/Android/Sdk -> $BASE/sdk (idempotente)
assert_symlink "$FAKE_DEST/sdk" "$FAKE_HOME/Android/Sdk" \
    "el lanzador crea \$HOME/Android/Sdk apuntando al sdk del destino"

if summarize; then
    exit 0
else
    exit 1
fi