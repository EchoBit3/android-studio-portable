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
uninstall_script="$REPO_DIR/uninstall.sh"

# Construimos un tar.gz mínimo e instalamos
tar_root="$TMP_ROOT/mktar"
mkdir -p "$tar_root/android-studio/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tar_root/android-studio/bin/studio.sh"
chmod +x "$tar_root/android-studio/bin/studio.sh"
FAKE_TAR="$TMP_ROOT/android-studio-fake.tar.gz"
tar -C "$tar_root" -czf "$FAKE_TAR" android-studio

bash "$setup_script" --dest "$FAKE_DEST" --tar "$FAKE_TAR" --home "$FAKE_HOME" >/dev/null 2>&1

printf '== Caja negra: uninstall.sh ==\n'

# 1. Retira la estructura completa
bash "$uninstall_script" --dest "$FAKE_DEST" --home "$FAKE_HOME" >/dev/null 2>&1
assert_eq "$?" "0" "uninstall.sh termina con código 0"
assert_true "[ ! -d '$FAKE_DEST' ]" "uninstall.sh elimina el destino completo"

# 2. Con --keep-binaries conserva android-studio/ y sdk/
bash "$setup_script" --dest "$FAKE_DEST" --tar "$FAKE_TAR" --home "$FAKE_HOME" >/dev/null 2>&1
bash "$uninstall_script" --dest "$FAKE_DEST" --home "$FAKE_HOME" --keep-binaries >/dev/null 2>&1
assert_true "[ -d '$FAKE_DEST/android-studio' ]" "uninstall --keep-binaries conserva android-studio/"
assert_true "[ ! -f '$FAKE_DEST/studio-portable.sh' ]" "uninstall --keep-binaries elimina el lanzador"

# 3. Retira el symlink cuando apunta a este destino
assert_true "[ ! -L '$FAKE_HOME/Android/Sdk' ]" "uninstall.sh retira el symlink Android/Sdk"

# 4. No toca un symlink ajeno
mkdir -p "$TMP_ROOT/otro/sdk"
ln -sfn "$TMP_ROOT/otro/sdk" "$FAKE_HOME/Android/Sdk"
bash "$uninstall_script" --dest "$FAKE_DEST" --home "$FAKE_HOME" --keep-binaries >/dev/null 2>&1
assert_true "[ -L '$FAKE_HOME/Android/Sdk' ]" "uninstall.sh no retira symlinks de otros destinos"

# 5. uninstall.sh falla sin --dest y documenta el flag
bash "$uninstall_script" >"$TMP_ROOT/nodest.log" 2>&1
assert_eq "$?" "1" "uninstall.sh sin --dest termina con código 1"
assert_true "grep -q -- '--dest' '$TMP_ROOT/nodest.log'" "uninstall.sh sin --dest imprime la ayuda con --dest"

# 6. uninstall.sh documenta --keep-binaries y --help
assert_true "bash '$uninstall_script' --help 2>&1 | grep -q -- '--keep-binaries'" \
    "uninstall.sh documenta --keep-binaries en --help"
assert_true "bash '$uninstall_script' --help 2>&1 | grep -q -- '--dest'" \
    "uninstall.sh documenta --dest en --help"

HOME="$SAVED_HOME"

if summarize; then
    exit 0
else
    exit 1
fi