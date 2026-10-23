#!/usr/bin/env bash
# install-emulator.sh: agrega el emulador y una imagen de sistema al SDK portable.
set -euo pipefail

DEST="${1:-}"
if [ -z "$DEST" ]; then
    printf 'Uso: %s <directorio-portable>\n' "$0" >&2
    exit 1
fi
DEST="$(readlink -f "$DEST")"
SDK="$DEST/sdk"
CMDLINE="$SDK/cmdline-tools/latest/bin/sdkmanager"
JAVA="${JAVA_HOME:-}"

if [ -z "$JAVA" ]; then
    if [ -x "$DEST/android-studio/jbr/bin/java" ]; then
        JAVA="$DEST/android-studio/jbr/bin/java"
        export JAVA_HOME="$DEST/android-studio/jbr"
    else
        printf 'No se encontro Java. Define JAVA_HOME.\n' >&2
        exit 1
    fi
fi

if [ ! -x "$CMDLINE" ]; then
    printf 'Descargando command-line tools...\n'
    mkdir -p "$SDK/cmdline-tools"
    TMP_ZIP="$DEST/tmp/cmdline-tools.zip"
    mkdir -p "$DEST/tmp"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$TMP_ZIP" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$TMP_ZIP" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    else
        printf 'Se requiere curl o wget.\n' >&2
        exit 1
    fi
    rm -rf "$SDK/cmdline-tools/latest"
    mkdir -p "$SDK/cmdline-tools/latest"
    unzip -q "$TMP_ZIP" -d "$SDK/cmdline-tools/latest"
    # reorganizar si vino en subcarpeta
    if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ] && [ -d "$SDK/cmdline-tools/latest/cmdline-tools" ]; then
        mv "$SDK/cmdline-tools/latest/cmdline-tools"/* "$SDK/cmdline-tools/latest/"
        rmdir "$SDK/cmdline-tools/latest/cmdline-tools" 2>/dev/null || true
    fi
    rm -f "$TMP_ZIP"
fi

export ANDROID_HOME="$SDK"
printf 'Aceptando licencias...\n'
yes | "$CMDLINE" --licenses >/dev/null 2>&1 || true

printf 'Instalando emulador, platform y system image...\n'
"$CMDLINE" "emulator" "platforms;android-36" "build-tools;36.0.0" "system-images;android-36;google_apis;x86_64"

printf 'Emulador instalado correctamente en %s\n' "$SDK/emulator"