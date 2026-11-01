#!/usr/bin/env bash
# install-emulator.sh: instala el emulador, platform-tools y una system image
# dentro del SDK portable creado por setup.sh, y opcionalmente un AVD en <dest>/avd.
# Uso: install-emulator.sh --dest <dir> [--image <pkg>] [--avd <nombre>] [--device <perfil>]
set -euo pipefail

# cmdline-tools oficiales de Google (Linux): el tar.gz del IDE no las trae, así que
# este script las descarga si el destino todavía no tiene sdkmanager. La revisión
# vigente se resuelve del XML oficial (repository2-3.xml) y, si eso falla, se usa
# una revisión pinneada como respaldo. URL y sha256 (opcional) por env.
CMDTOOLS_XML_URL="${PORTABLE_TOOLS_XML_URL:-https://dl.google.com/android/repository/repository2-3.xml}"
CMDTOOLS_PINNED="${PORTABLE_TOOLS_URL:-https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip}"
CMDTOOLS_SHA="${PORTABLE_TOOLS_SHA256:-}"
DEFAULT_IMAGE="${PORTABLE_DEFAULT_IMAGE:-system-images;android-35;google_apis;x86_64}"

DEST=""
IMAGE="$DEFAULT_IMAGE"
AVD=""
DEVICE=""
SDKMGR_OVERRIDE=""

usage() {
    cat <<'EOF'
Uso: install-emulator.sh --dest <dir> [opciones]

Opciones:
  --dest DIR         Instalación portable creada por setup.sh (obligatorio)
  --image PAQUETE    System image a instalar
                     (por defecto system-images;android-35;google_apis;x86_64)
  --avd NOMBRE       Crea un AVD con esa imagen tras instalar (opcional)
  --device PERFIL    Perfil de dispositivo para --avd (opcional, ej. pixel)
  --sdkmanager RUTA  Usa este sdkmanager en vez del del SDK portable
  --help             Muestra esta ayuda

Todo queda dentro de <dest> (sdk/, avd/, .android/, tmp/ y el JBR del IDE):
mismo criterio de portabilidad que el lanzador studio-portable.sh.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dest) DEST="${2:-}"; shift 2 ;;
        --image) IMAGE="${2:-}"; shift 2 ;;
        --avd) AVD="${2:-}"; shift 2 ;;
        --device) DEVICE="${2:-}"; shift 2 ;;
        --sdkmanager) SDKMGR_OVERRIDE="${2:-}"; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Opción desconocida: %s\n' "$1" >&2; usage; exit 1 ;;
    esac
done

if [ -z "$DEST" ]; then
    printf 'Falta --dest <dir>\n' >&2
    usage
    exit 1
fi

DEST="$(readlink -f "$DEST")"
if [ ! -d "$DEST" ]; then
    printf 'El destino no existe: %s\n' "$DEST" >&2
    exit 1
fi

# El IDE es requisito: trae el JBR con Java que cmdline-tools necesita.
if [ ! -x "$DEST/android-studio/bin/studio" ] && [ ! -x "$DEST/android-studio/bin/studio.sh" ]; then
    printf 'No hay Android Studio en %s/android-studio\n' "$DEST" >&2
    printf 'Corré setup.sh --dest %s primero.\n' "$DEST" >&2
    exit 1
fi

# Mismo entorno portable que el lanzador: nada sale de la carpeta.
export ANDROID_HOME="$DEST/sdk"
export ANDROID_SDK_ROOT="$DEST/sdk"
export ANDROID_USER_HOME="$DEST/.android"
export ANDROID_AVD_HOME="$DEST/avd"
export JAVA_HOME="$DEST/android-studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p "$DEST/avd" "$DEST/.android" "$DEST/tmp"
SDK_ROOT="$DEST/sdk"

# find_sdkmanager: el del SDK portable (cmdline-tools/latest) o cualquier versión instalada.
find_sdkmanager() {
    local p
    for p in "$DEST/sdk/cmdline-tools/latest/bin/sdkmanager" \
             "$DEST/sdk"/cmdline-tools/*/bin/sdkmanager; do
        if [ -x "$p" ]; then
            printf '%s\n' "$p"
            return 0
        fi
    done
    return 1
}

# cmdline_tools_url: resuelve la última revisión Linux del XML oficial; fallback pinneado.
cmdline_tools_url() {
    local xml file
    if command -v curl >/dev/null 2>&1; then
        xml="$(curl -fsSL --max-time 30 "$CMDTOOLS_XML_URL" 2>/dev/null)" || xml=""
    fi
    if [ -n "${xml:-}" ]; then
        file="$(printf '%s' "$xml" | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' \
            | sort -u | sort -t- -k3 -n | tail -n 1)"
    fi
    if [ -n "${file:-}" ]; then
        printf 'https://dl.google.com/android/repository/%s\n' "$file"
    else
        printf '%s\n' "$CMDTOOLS_PINNED"
    fi
}

# install_cmdline_tools: descarga y despliega cmdline-tools bajo sdk/cmdline-tools/latest.
install_cmdline_tools() {
    local zip_file="$DEST/tmp/cmdline-tools.zip"
    local url got
    command -v unzip >/dev/null 2>&1 || return 1
    url="$(cmdline_tools_url)"
    if [ ! -f "$zip_file" ]; then
        curl -fSL --progress-bar -o "$zip_file" "$url"
    fi
    if [ -n "$CMDTOOLS_SHA" ] && command -v sha256sum >/dev/null 2>&1; then
        got="$(sha256sum "$zip_file" 2>/dev/null | awk '{print $1}')"
        if [ "$got" != "$CMDTOOLS_SHA" ]; then
            rm -f "$zip_file"
            printf 'sha256 de cmdline-tools no coincide; descartado\n' >&2
            return 1
        fi
    fi
    command -v unzip >/dev/null 2>&1 || {
        printf 'Falta unzip para extraer cmdline-tools; instalalo o pasá --sdkmanager <ruta>\n' >&2
        return 1
    }
    rm -rf "$DEST/sdk/cmdline-tools"
    mkdir -p "$DEST/sdk/cmdline-tools"
    unzip -q "$zip_file" -d "$DEST/sdk/cmdline-tools"
    mv "$DEST/sdk/cmdline-tools/cmdline-tools" "$DEST/sdk/cmdline-tools/latest"
    rm -f "$zip_file"
}

if [ -n "$SDKMGR_OVERRIDE" ]; then
    if [ ! -x "$SDKMGR_OVERRIDE" ]; then
        printf 'sdkmanager inaccesible: %s\n' "$SDKMGR_OVERRIDE" >&2
        exit 1
    fi
    SDKMGR="$SDKMGR_OVERRIDE"
else
    SDKMGR="$(find_sdkmanager)" || {
        printf 'No hay sdkmanager en %s; descargando cmdline-tools de Google...\n' "$SDK_ROOT" >&2
        command -v curl >/dev/null 2>&1 || {
            printf 'Falta curl para descargar cmdline-tools; pasá --sdkmanager <ruta>\n' >&2
            exit 1
        }
        command -v unzip >/dev/null 2>&1 || {
            printf 'Falta unzip para extraer cmdline-tools; instalalo (ej. sudo apt install unzip) o pasá --sdkmanager <ruta>\n' >&2
            exit 1
        }
        install_cmdline_tools || exit 1
        SDKMGR="$(find_sdkmanager)" || {
            printf 'No se pudo localizar sdkmanager tras la instalación\n' >&2
            exit 1
        }
    }
fi
printf 'sdkmanager: %s\n' "$SDKMGR"

printf 'Aceptando licencias del SDK...\n'
yes | "$SDKMGR" --licenses --sdk_root="$SDK_ROOT" >/dev/null 2>&1 || true

printf 'Instalando emulator, platform-tools y %s\n' "$IMAGE"
"$SDKMGR" --sdk_root="$SDK_ROOT" "emulator" "platform-tools" "$IMAGE" < /dev/null

if [ -n "$AVD" ]; then
    AVDMGR="$(dirname "$SDKMGR")/avdmanager"
    if [ ! -x "$AVDMGR" ]; then
        printf 'No se encontró avdmanager junto a sdkmanager\n' >&2
        exit 1
    fi
    DEV_ARGS=()
    if [ -n "$DEVICE" ]; then
        DEV_ARGS=(-d "$DEVICE")
    fi
    printf 'no\n' > "$DEST/tmp/avd-answer"
    printf 'Creando AVD: %s\n' "$AVD"
    "$AVDMGR" create avd -n "$AVD" -k "$IMAGE" "${DEV_ARGS[@]+${DEV_ARGS[@]}}" \
        < "$DEST/tmp/avd-answer"
    rm -f "$DEST/tmp/avd-answer"
fi

printf 'Emulador instalado en: %s/sdk/emulator\n' "$DEST"
if [ -n "$AVD" ]; then
    printf 'AVD disponible en: %s/avd/%s.avd\n' "$DEST" "$AVD"
fi
exit 0
