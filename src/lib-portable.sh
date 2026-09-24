#!/usr/bin/env bash
# lib-portable.sh: resolución, descarga y activación de actualizaciones del IDE.

# Fuente autoritativa: Google. Fallback: manifiesto version.json del repo.
UPDATE_MANIFEST_URL="${PORTABLE_MANIFEST_URL:-https://raw.githubusercontent.com/EchoBit3/android-studio-portable/main/version.json}"
UPDATE_CACHE_TTL=86400
# Límites de red: metadata rápida, descarga del IDE generosa (por defecto 2 h)
PORTABLE_META_TIMEOUT="${PORTABLE_META_TIMEOUT:-30}"
PORTABLE_DOWNLOAD_TIMEOUT="${PORTABLE_DOWNLOAD_TIMEOUT:-7200}"

# fetch_archive <src> <out>: copia un archivo local o descarga una URL https/file.
fetch_archive() {
    local src="$1"
    local out="$2"
    if [ -f "$src" ]; then
        cp "$src" "$out"
    elif [ "${src#file://}" != "$src" ]; then
        cp "${src#file://}" "$out"
    elif [ "${src#http://}" != "$src" ] || [ "${src#https://}" != "$src" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fSL --max-time "$PORTABLE_DOWNLOAD_TIMEOUT" -C - --progress-bar -o "$out" "$src"
        elif command -v wget >/dev/null 2>&1; then
            wget -c -O "$out" "$src"
        else
            return 1
        fi
    else
        return 1
    fi
}

# stable_url: resuelve la URL del tar.gz estable oficial vigente
stable_url() {
    local page
    page="$(curl -fsSL --max-time "$PORTABLE_META_TIMEOUT" -A 'Mozilla/5.0' 'https://developer.android.com/studio')" || return 1
    printf '%s' "$page" | grep -oE \
        'https://(dl\.google\.com|redirector\.gvt1\.com|edgedl\.me\.gvt1\.com)[^" ]*ide-zips/[0-9.]+/android-studio[^" ]*-linux\.tar\.gz' \
        | head -n 1 || return 1
}

# page_manifest <html>: extrae "url sha256" de la fila Linux en la página oficial
page_manifest() {
    local page="$1"
    local url base row sha
    url="$(printf '%s' "$page" | grep -oE \
        'https://[^" ]*ide-zips/[0-9.]+/android-studio[^" ]*-linux\.tar\.gz' | head -n 1)" || return 1
    [ -n "$url" ] || return 1
    base="$(basename "$url")"
    row="$(printf '%s' "$page" | sed 's/></>\n</g' | awk -v base="$base" '
        /^[[:space:]]*<tr/ { row = $0 }
        row != "" && !/^[[:space:]]*<tr/ { row = row $0 }
        /^[[:space:]]*<\/tr>/ {
            if (index(row, base) > 0) { print row; exit }
            row = ""
        }
    ')" || return 1
    [ -n "$row" ] || return 1
    sha="$(printf '%s' "$row" | grep -oE '[a-f0-9]{64}' | head -n 1)" || return 1
    [ -n "$sha" ] || return 1
    printf '%s %s\n' "$url" "$sha"
}

# repo_manifest: extrae "url sha256 version" del version.json del repo
repo_manifest() {
    local src="$UPDATE_MANIFEST_URL"
    local raw url sha ver
    if [ -f "$src" ]; then
        raw="$(cat "$src")"
    elif [ "${src#file://}" != "$src" ]; then
        raw="$(cat "${src#file://}")"
    elif command -v curl >/dev/null 2>&1; then
        raw="$(curl -fsSL --max-time "$PORTABLE_META_TIMEOUT" "$src")" || return 1
    else
        return 1
    fi
    [ -n "$raw" ] || return 1
    url="$(printf '%s' "$raw" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)" || return 1
    sha="$(printf '%s' "$raw" | sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)" || return 1
    ver="$(printf '%s' "$raw" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)" || return 1
    [ -n "$url" ] && [ -n "$sha" ] && [ -n "$ver" ] || return 1
    printf '%s %s %s\n' "$url" "$sha" "$ver"
}

# version_from_url <url>: extrae la versión de la ruta ide-zips/<version>/
version_from_url() {
    local url="$1"
    printf '%s' "$url" | grep -oE 'ide-zips/[0-9.]+' | head -n 1 | sed 's#ide-zips/##' || return 1
}

# version_gt <a> <b>: exit 0 si a > b, comparando campos numéricos por puntos
version_gt() {
    [ "$#" -eq 2 ] || return 2
    [ "$1" != "$2" ] || return 1
    local IFS='.' ra rb i n av bv
    read -r -a ra <<< "$1"
    read -r -a rb <<< "$2"
    n=$(( ${#ra[@]} > ${#rb[@]} ? ${#ra[@]} : ${#rb[@]} ))
    for ((i = 0; i < n; i++)); do
        av="${ra[$i]:-0}"
        bv="${rb[$i]:-0}"
        if (( 10#$av > 10#$bv )); then return 0; fi
        if (( 10#$av < 10#$bv )); then return 1; fi
    done
    return 1
}

# installed_version <base>: versión desde product-info.json o .studio-version
installed_version() {
    local base="$1"
    local v=""
    if [ -f "$base/android-studio/product-info.json" ]; then
        v="$(sed -n 's/.*"dataDirectoryName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
            "$base/android-studio/product-info.json" | head -n 1)" || return 1
        v="${v#AndroidStudio}"
    elif [ -f "$base/.studio-version" ]; then
        v="$(cat "$base/.studio-version")"
    fi
    printf '%s' "$v"
}

# update_ide <base> <url> <sha> <ver>: descarga, verifica, preflight y swap atómico
update_ide() {
    local base="$1" url="$2" sha="$3" ver="$4"
    local tar="$base/tmp/.update.tar.gz"
    local stage="$base/tmp/update-stage"
    local got
    mkdir -p "$base/tmp" "$stage"
    rm -rf "$stage/.tmp-extract" && mkdir -p "$stage/.tmp-extract"
    fetch_archive "$url" "$tar" || return 1
    got="$(sha256sum "$tar" 2>/dev/null | awk '{print $1}')" || return 1
    [ "$got" = "$sha" ] || { rm -f "$tar"; return 1; }
    if tar -tzf "$tar" | grep -qE '(^/|(^|/)\.\.(/|$))'; then
        rm -f "$tar"
        return 1
    fi
    tar -C "$stage/.tmp-extract" --no-same-owner -xzf "$tar"
    rm -f "$tar"
    [ -x "$stage/.tmp-extract/android-studio/bin/studio.sh" ] || return 1
    [ -x "$stage/.tmp-extract/android-studio/jbr/bin/java" ] || return 1
    [ -f "$stage/.tmp-extract/android-studio/product-info.json" ] || return 1
    if [ -d "$base/android-studio" ]; then
        rm -rf "$base/android-studio.prev"
        mv "$base/android-studio" "$base/android-studio.prev"
    fi
    mv "$stage/.tmp-extract/android-studio" "$base/android-studio"
    printf '%s\n' "$ver" > "$base/.studio-version"
    return 0
}

# rollback <base>: restaura la instalación previa si sigue disponible
rollback() {
    local base="$1"
    [ -d "$base/android-studio.prev" ] || return 1
    rm -rf "$base/android-studio"
    mv "$base/android-studio.prev" "$base/android-studio"
    installed_version "$base" > "$base/.studio-version"
    return 0
}

# check_update <base>: revisa Google (con caché 24h) y aplica el update si hay nueva.
# Retorna 10 si se aplicó una actualización, 0 en caso contrario.
check_update() {
    local base="$1"
    local now stamp cstamp cu cv v_inst c_ver c_url c_sha m_url m_sha m_ver page
    [ -n "$base" ] || return 0
    [ "${PORTABLE_NO_UPDATE:-0}" = "1" ] && return 0
    command -v flock >/dev/null 2>&1 || return 0
    mkdir -p "$base/tmp" "$base/.config"
    exec 9>"$base/tmp/.update.lock" 2>/dev/null || return 0
    flock -n 9 2>/dev/null || return 0
    v_inst="$(installed_version "$base")" || return 0
    [ -n "$v_inst" ] || return 0
    now="$(date +%s)"
    cache="$base/.config/update-cache"
    c_ver="" c_url="" c_sha="" cstamp="0"
    if [ -f "$cache" ]; then
        read -r cstamp c_url c_sha c_ver < "$cache"
    fi
    if [ -n "$c_ver" ] && [ "$(( now - cstamp ))" -lt "$UPDATE_CACHE_TTL" ]; then
        m_url="$c_url"; m_sha="$c_sha"; m_ver="$c_ver"
    else
        m_url="" m_sha="" m_ver=""
        if [ -n "${PORTABLE_PAGE_FILE:-}" ] && [ -f "$PORTABLE_PAGE_FILE" ]; then
            page="$(cat "$PORTABLE_PAGE_FILE")"
            set -- $(page_manifest "$page") && fok=1
        elif command -v curl >/dev/null 2>&1; then
            page="$(curl -fsSL --max-time "$PORTABLE_META_TIMEOUT" -A 'Mozilla/5.0' 'https://developer.android.com/studio')" || page=""
            if [ -n "$page" ]; then
                set -- $(page_manifest "$page") && fok=1
            fi
        fi
        if [ "${fok:-0}" = "1" ]; then
            m_url="$1"; m_sha="$2"; m_ver="$(version_from_url "$m_url")"
        else
            set -- $(repo_manifest) && r_ok=1
            if [ "${r_ok:-0}" = "1" ]; then
                m_url="$1"; m_sha="$2"; m_ver="$3"
            fi
        fi
        if [ -n "$m_url" ] && [ -n "$m_ver" ]; then
            printf '%s %s %s %s\n' "$now" "$m_url" "$m_sha" "$m_ver" > "$cache"
        else
            [ -n "$c_ver" ] && { m_url="$c_url"; m_sha="$c_sha"; m_ver="$c_ver"; }
        fi
    fi
    [ -n "$m_url" ] || return 0
    if version_gt "$m_ver" "$v_inst"; then
        update_ide "$base" "$m_url" "$m_sha" "$m_ver" || return 0
        return 10
    fi
    return 0
}