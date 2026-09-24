#!/usr/bin/env bash
# setup.sh: instala Android Studio portable autocontenido en un directorio.
# Uso: setup.sh --dest <dir> [--tar <ruta|url>] [--home <dir>] [--no-symlink]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

DEST=""
TAR_SRC=""
HOME_DIR="$HOME"
DO_SYMLINK=1

usage() {
    cat <<'EOF'
Uso: setup.sh --dest <dir> [opciones]

Opciones:
  --dest DIR       Directorio destino de la instalación portable (obligatorio)
  --tar RUTA|URL   tar.gz de Android Studio Linux, o URL para descargarlo.
                   Si se omite, se resuelve la última versión estable desde
                   developer.android.com/studio y se descarga (requiere curl).
  --home DIR       Directorio $HOME objetivo para el symlink Android/Sdk
                   (por defecto $HOME real)
  --no-symlink     No crear $HOME/Android/Sdk -> <dest>/sdk
  --help           Muestra esta ayuda

Requiere: tar, curl o wget. Se genera en <dest> la estructura autocontenida
(sdk, avd, .gradle, .android, configs de JetBrains, temporales) más el
lanzador studio-portable.sh.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dest) DEST="${2:-}"; shift 2 ;;
        --tar) TAR_SRC="${2:-}"; shift 2 ;;
        --home) HOME_DIR="${2:-}"; shift 2 ;;
        --no-symlink) DO_SYMLINK=0; shift ;;
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

create_tree() {
    mkdir -p "$DEST"
    local d
    for d in sdk avd .gradle .android .config .cache tmp \
             AndroidStudioConfig AndroidStudioSystem AndroidStudioPlugins AndroidStudioLogs; do
        mkdir -p "$DEST/$d"
    done
    mkdir -p "$DEST/.local/share"
}

# fetch_tar <src>: copia un archivo local o descarga una URL a android-studio.tar.gz
fetch_tar() {
    local src="$1"
    local out="$DEST/android-studio.tar.gz"
    if [ -f "$src" ]; then
        cp "$src" "$out"
    elif printf '%s' "$src" | grep -qE '^https?://'; then
        if command -v curl >/dev/null 2>&1; then
            curl -L --fail --progress-bar -o "$out" "$src"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$out" "$src"
        else
            printf 'Ni curl ni wget disponibles para descargar %s\n' "$src" >&2
            exit 1
        fi
    else
        printf 'No existe el archivo --tar: %s\n' "$src" >&2
        exit 1
    fi
}

# stable_url: resuelve la URL del tar.gz estable oficial vigente
stable_url() {
    local page
    page="$(curl -fsSL -A 'Mozilla/5.0' 'https://developer.android.com/studio')" || return 1
    printf '%s' "$page" | grep -oE \
        'https://(dl\.google\.com|redirector\.gvt1\.com|edgedl\.me\.gvt1\.com)[^" ]*ide-zips/[0-9.]+/android-studio[^" ]*-linux\.tar\.gz' \
        | head -n 1
}

extract_studio() {
    if [ -x "$DEST/android-studio/bin/studio.sh" ]; then
        return
    fi
    local tmp_tar="$DEST/android-studio.tar.gz"
    if [ -n "${TAR_SRC:-}" ]; then
        fetch_tar "$TAR_SRC"
    elif command -v curl >/dev/null 2>&1; then
        local url
        url="$(stable_url)" || {
            printf 'Fallo al resolver la URL estable; usá --tar <ruta|url>\n' >&2
            exit 1
        }
        curl -L --fail --progress-bar -o "$tmp_tar" "$url" || {
            printf 'Fallo la descarga de %s\n' "$url" >&2
            exit 1
        }
    else
        printf 'Falta --tar <ruta|url> y no hay curl para resolver la estable\n' >&2
        exit 1
    fi
    # Rechaza entradas con rutas absolutas o saltos de directorio antes de extraer
    if tar -tzf "$tmp_tar" | grep -qE '(^/|(^|/)\.\.(/|$))'; then
        printf 'El tar.gz contiene rutas peligrosas y fue rechazado\n' >&2
        rm -f "$tmp_tar"
        exit 1
    fi
    tar -C "$DEST" --no-same-owner -xzf "$tmp_tar"
    rm -f "$tmp_tar"
}

generate_launcher() {
    install -m 0755 "$SCRIPT_DIR/src/studio-portable.sh.in" "$DEST/studio-portable.sh"
}

generate_properties() {
    install -m 0644 "$SCRIPT_DIR/src/studio.properties.in" "$DEST/studio.properties"
}

generate_sdk_state() {
    local store="$DEST/AndroidStudioConfig/options/AndroidSdkPathStore.xml"
    mkdir -p "$(dirname "$store")"
    cat > "$store" << XML
<application>
  <component name="AndroidSdkPathStore">
    <option name="androidSdkAbsolutePath" value="$DEST/sdk" />
  </component>
</application>
XML
}

link_sdk() {
    if [ "$DO_SYMLINK" -eq 1 ]; then
        mkdir -p "$HOME_DIR/Android"
        ln -sfn "$DEST/sdk" "$HOME_DIR/Android/Sdk"
    fi
}

create_tree
extract_studio
generate_launcher
generate_properties
generate_sdk_state
link_sdk

printf 'Android Studio portable instalado en: %s\n' "$DEST"
printf 'Lanzador: %s\n' "$DEST/studio-portable.sh"
[ "$DO_SYMLINK" -eq 1 ] && printf 'Symlink: %s/Android/Sdk -> %s/sdk\n' "$HOME_DIR" "$DEST"
exit 0