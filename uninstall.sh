#!/usr/bin/env bash
# uninstall.sh: revierte lo que creó setup.sh en el directorio destino.
# Uso: uninstall.sh --dest <dir> [--keep-binaries] [--home <dir>]
set -euo pipefail

DEST=""
HOME_DIR="$HOME"
KEEP_BINARIES=0

usage() {
    cat <<'EOF'
Uso: uninstall.sh --dest <dir> [opciones]

Opciones:
  --dest DIR        Directorio de la instalación portable (obligatorio)
  --home DIR        Directorio $HOME cuyo symlink Android/Sdk se retira
                    (por defecto $HOME real)
  --keep-binaries   No borrar android-studio/ ni sdk/ (solo scripts y state)
  --help            Muestra esta ayuda
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dest) DEST="${2:-}"; shift 2 ;;
        --home) HOME_DIR="${2:-}"; shift 2 ;;
        --keep-binaries) KEEP_BINARIES=1; shift ;;
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

# Retira el symlink $HOME/Android/Sdk solo si apunta a este destino
sdklink="$HOME_DIR/Android/Sdk"
if [ -L "$sdklink" ] && [ "$(readlink -f "$sdklink")" = "$DEST/sdk" ]; then
    rm -f "$sdklink"
fi

rm -f "$DEST/studio-portable.sh"
rm -f "$DEST/studio.properties"
rm -rf "$DEST/AndroidStudioConfig/options/AndroidSdkPathStore.xml"
rm -rf "$DEST/AndroidStudioConfig/options" 2>/dev/null || true

if [ "$KEEP_BINARIES" -eq 1 ]; then
    printf 'Binarios conservados en: %s/android-studio y %s/sdk\n' "$DEST" "$DEST"
else
    rm -rf "$DEST"
fi

printf 'Instalación portable retirada (destino: %s)\n' "$DEST"
exit 0