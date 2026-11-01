#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_DEST="$TMP_ROOT/dest"
LOG_SDM="$TMP_ROOT/sdkmanager.log"
LOG_AVD="$TMP_ROOT/avdmanager.log"

emulator_script="$REPO_DIR/install-emulator.sh"

# Estructura mínima del destino: IDE con estructura (bin/studio) y entorno portable
mkdir -p "$FAKE_DEST/android-studio/bin" "$FAKE_DEST/sdk" "$FAKE_DEST/avd"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_DEST/android-studio/bin/studio"
chmod +x "$FAKE_DEST/android-studio/bin/studio"

# sdkmanager/avdmanager falsos: logean args y variables relevantes, y salen 0
STUBS="$FAKE_DEST/sdk/cmdline-tools/latest/bin"
mkdir -p "$STUBS"
cat > "$STUBS/sdkmanager" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$LOG_SDM"
env | grep -E "ANDROID_(HOME|SDK_ROOT|AVD_HOME|USER_HOME)|JAVA_HOME" >> "$LOG_SDM"
exit 0
EOF
cat > "$STUBS/avdmanager" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$LOG_AVD"
exit 0
EOF
chmod +x "$STUBS/sdkmanager" "$STUBS/avdmanager"

printf '== Caja negra: install-emulator.sh ==\n'

# 1. Sintaxis y ejecutabilidad del script
assert_true "bash -n '$emulator_script'" "install-emulator.sh pasa bash -n"
assert_true "[ -x '$emulator_script' ]" "install-emulator.sh es ejecutable"

# 2. Falla sin --dest y documenta los flags
bash "$emulator_script" >"$TMP_ROOT/nodest.log" 2>&1
assert_eq "$?" "1" "install-emulator.sh sin --dest termina con código 1"
assert_true "grep -q -- '--dest' '$TMP_ROOT/nodest.log'" \
    "install-emulator.sh sin --dest imprime la ayuda con --dest"
assert_true "grep -q -- '--image' '$TMP_ROOT/nodest.log'" \
    "install-emulator.sh documenta --image en la ayuda"

# 3. Falla si el destino no tiene Android Studio
mkdir -p "$TMP_ROOT/vacio/sdk"
bash "$emulator_script" --dest "$TMP_ROOT/vacio" >"$TMP_ROOT/noide.log" 2>&1
assert_eq "$?" "1" "install-emulator.sh falla sin android-studio/ en el destino"

# 4. Instala usando el sdkmanager del SDK portable y respeta el --image
IMG="system-images;android-35;google_apis;x86_64"
bash "$emulator_script" --dest "$FAKE_DEST" --image "$IMG" >/dev/null 2>&1
assert_eq "$?" "0" "install-emulator.sh termina con código 0"
assert_true "grep -qE '(^|[[:space:]])emulator([[:space:]]|$)' '$LOG_SDM'" \
    "sdkmanager recibe el paquete emulator"
assert_true "grep -qE '(^|[[:space:]])platform-tools([[:space:]]|$)' '$LOG_SDM'" \
    "sdkmanager recibe el paquete platform-tools"
assert_true "grep -qF '$IMG' '$LOG_SDM'" "sdkmanager recibe la system image pedida"
assert_true "grep -q -- '--sdk_root=$FAKE_DEST/sdk' '$LOG_SDM'" \
    "sdkmanager apunta al SDK portable"

# 5. Entorno portable: variables exportadas apuntan al destino
assert_true "grep -q 'ANDROID_AVD_HOME=$FAKE_DEST/avd' '$LOG_SDM'" \
    "ANDROID_AVD_HOME apunta a <dest>/avd"
assert_true "grep -q 'ANDROID_USER_HOME=$FAKE_DEST/.android' '$LOG_SDM'" \
    "ANDROID_USER_HOME apunta a <dest>/.android"
assert_true "grep -q 'JAVA_HOME=$FAKE_DEST/android-studio/jbr' '$LOG_SDM'" \
    "JAVA_HOME usa el JBR del IDE portable"
assert_true "grep -q -- '--licenses' '$LOG_SDM'" \
    "acepta licencias del SDK antes de instalar"

# 6. Con --avd invoca avdmanager junto a sdkmanager con el nombre y la imagen
: > "$LOG_AVD"
bash "$emulator_script" --dest "$FAKE_DEST" --image "$IMG" --avd prueba --device pixel >/dev/null 2>&1
assert_eq "$?" "0" "install-emulator.sh con --avd termina con código 0"
assert_true "grep -qF 'create avd -n prueba -k $IMG' '$LOG_AVD'" \
    "avdmanager crea el AVD con el nombre y la imagen pedidos"
assert_true "grep -qF 'pixel' '$LOG_AVD'" "avdmanager recibe el perfil de dispositivo"

# 7. Override de sdkmanager inaccesible es un error controlado
bash "$emulator_script" --dest "$FAKE_DEST" --sdkmanager "$TMP_ROOT/no-such-sdkmanager" \
    >"$TMP_ROOT/badskm.log" 2>&1
assert_eq "$?" "1" "install-emulator.sh con --sdkmanager inexistente falla con código 1"

# 8. Sin unzip avisa antes de descargar (no baja los ~150 MB de cmdline-tools)
NO_UNZIP_BIN="$TMP_ROOT/bin-sin-unzip"
mkdir -p "$NO_UNZIP_BIN"
for t in bash sh readlink mkdir find grep sed awk cat sort head tail cut tr wc uname; do
    p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$NO_UNZIP_BIN/$t"
done
cat > "$NO_UNZIP_BIN/curl" <<EOF
#!/usr/bin/env bash
touch "$TMP_ROOT/curl-invocado"
exit 1
EOF
chmod +x "$NO_UNZIP_BIN/curl"

DEST_SIN_UNZIP="$TMP_ROOT/dest-sin-unzip"
mkdir -p "$DEST_SIN_UNZIP/android-studio/bin" "$DEST_SIN_UNZIP/sdk"
printf '#!/usr/bin/env bash\nexit 0\n' > "$DEST_SIN_UNZIP/android-studio/bin/studio"
chmod +x "$DEST_SIN_UNZIP/android-studio/bin/studio"

PATH="$NO_UNZIP_BIN" bash "$emulator_script" --dest "$DEST_SIN_UNZIP" \
    >"$TMP_ROOT/sin-unzip.log" 2>&1
assert_eq "$?" "1" "sin unzip falla con código 1"
assert_true "grep -q 'unzip' '$TMP_ROOT/sin-unzip.log'" \
    "sin unzip el mensaje nombra la dependencia que falta"
assert_true "[ ! -f '$TMP_ROOT/curl-invocado' ]" \
    "sin unzip no descarga cmdline-tools antes de avisar"

if summarize; then
    exit 0
else
    exit 1
fi
