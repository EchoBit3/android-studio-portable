#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# shellcheck source=src/lib-portable.sh
source "$REPO_DIR/src/lib-portable.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_BASE="$TMP_ROOT/instalacion"
mkdir -p "$FAKE_BASE/android-studio/bin" "$FAKE_BASE/android-studio/jbr/bin"

printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_BASE/android-studio/bin/studio.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_BASE/android-studio/jbr/bin/java"
printf '{"dataDirectoryName":"AndroidStudio2026.1.4"}\n' > "$FAKE_BASE/android-studio/product-info.json"
chmod +x "$FAKE_BASE/android-studio/bin/studio.sh" "$FAKE_BASE/android-studio/jbr/bin/java"

printf '== Caja negra: lógica de actualización ==\n'

# 1. version_gt compara campos numéricos por puntos
assert_true "version_gt '2026.1.4.8' '2026.1.4'" "2026.1.4.8 es mayor que 2026.1.4"
assert_true "! version_gt '2026.1.4' '2026.1.4.8'" "2026.1.4 no es mayor que 2026.1.4.8"
assert_true "version_gt '2.0' '1.9'" "2.0 es mayor que 1.9"
assert_true "! version_gt '1.9' '2.0'" "1.9 no es mayor que 2.0"
assert_true "! version_gt '2026.1.4' '2026.1.4'" "iguales no es mayor"

# 2. installed_version lee product-info.json (sin .studio-version todavía)
assert_eq "$(installed_version "$FAKE_BASE")" "2026.1.4" \
    "installed_version deriva la versión desde product-info.json"

# 2b. .studio-version manda sobre product-info.json: un patch (2026.1.4.8)
# no cambia dataDirectoryName (AndroidStudio2026.1.4) y no debe provocar
# re-descarga en loop ni versión regresiva.
PATCH_BASE="$TMP_ROOT/instalacion-patch"
mkdir -p "$PATCH_BASE/android-studio"
printf '{"dataDirectoryName":"AndroidStudio2026.1.4"}\n' > "$PATCH_BASE/android-studio/product-info.json"
printf '2026.1.4.8\n' > "$PATCH_BASE/.studio-version"
assert_eq "$(installed_version "$PATCH_BASE")" "2026.1.4.8" \
    "installed_version prioriza .studio-version (patch sin cambio de dataDir)"

# 3. version_from_url extrae la versión de la ruta ide-zips
assert_eq "$(version_from_url 'https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.4.8/x-linux.tar.gz')" "2026.1.4.8" \
    "version_from_url extrae la versión de la URL"

# 4. update_ide hace swap atómico y deja el respaldo .prev
UPDATE_URL="file://$TMP_ROOT/dist/0.0.0.tar.gz"
UPDATE_SHA="sha256sum_pendiente"
mkdir -p "$TMP_ROOT/dist"
tar_root="$TMP_ROOT/nuevo"
mkdir -p "$tar_root/android-studio/bin" "$tar_root/android-studio/jbr/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tar_root/android-studio/bin/studio.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tar_root/android-studio/jbr/bin/java"
printf '{"dataDirectoryName":"AndroidStudio2026.1.4XP"}\n' > "$tar_root/android-studio/product-info.json"
chmod +x "$tar_root/android-studio/bin/studio.sh" "$tar_root/android-studio/jbr/bin/java"
tar -C "$tar_root" -czf "$TMP_ROOT/dist/0.0.0.tar.gz" android-studio
UPDATE_SHA="$(sha256sum "$TMP_ROOT/dist/0.0.0.tar.gz" | awk '{print $1}')"

assert_true "update_ide '$FAKE_BASE' '$UPDATE_URL' '$UPDATE_SHA' '0.0.0'" \
    "update_ide descarga, verifica e intercambia la instalación"
assert_file_exists "$FAKE_BASE/.studio-version" "update_ide escribe .studio-version"
assert_eq "$(cat "$FAKE_BASE/.studio-version")" "0.0.0" "update_ide escribe la versión nueva"
assert_true "[ -d '$FAKE_BASE/android-studio.prev' ]" \
    "update_ide conserva la instalación anterior como .prev"
assert_file_exists "$FAKE_BASE/android-studio/bin/studio.sh" \
    "el desplegado nuevo tiene su binario"

# 5. rollback restaura el .prev
assert_true "rollback '$FAKE_BASE'" "rollback restaura la instalación previa"
assert_true "[ ! -d '$FAKE_BASE/android-studio.prev' ]" \
    "rollback consume el respaldo .prev"

# 6. sha256 incorrecto: no se toca la instalación
printf 'basura' > "$TMP_ROOT/dist/malo.tar.gz"
assert_true "! update_ide '$FAKE_BASE' 'file://$TMP_ROOT/dist/malo.tar.gz' '0000000000000000000000000000000000000000000000000000000000000000' '9.9.9'" \
    "update_ide rechaza un sha256 que no coincide"
assert_eq "$(cat "$FAKE_BASE/.studio-version")" "2026.1.4" \
    "con sha inválido mantiene la versión registrada (la restaurada)"

# 7. page_manifest extrae url y sha256 de la fila Linux de la página oficial
cat > "$TMP_ROOT/studio-page.html" <<'HTML'
<html><body><a href="https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.4.8/android-studio-xpro-linux.tar.gz">descarga</a>
<table><tr>
<td>Windows</td><td>android-studio-xpro-windows.exe</td><td>aaa</td>
</tr>
    <tr>
      <td>Linux</td>
      <td><button>android-studio-xpro-linux.tar.gz</button></td>
      <td>25c97ca6c6b505f2a20bff962dfd28718327f61e25b09a9bc915f1dae7b1e534</td>
    </tr></table></body></html>
HTML
MANIFEST_OUT="$(page_manifest "$(cat "$TMP_ROOT/studio-page.html")")"
assert_eq "$MANIFEST_OUT" "https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.4.8/android-studio-xpro-linux.tar.gz 25c97ca6c6b505f2a20bff962dfd28718327f61e25b09a9bc915f1dae7b1e534" \
    "page_manifest extrae url y sha256 de la fila Linux"

# 8. repo_manifest extrae url, sha256 y version del manifest
cat > "$TMP_ROOT/version.json" <<'JSON'
{
  "version": "2026.1.4.8",
  "url": "https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.4.8/android-studio-xpro-linux.tar.gz",
  "sha256": "25c97ca6c6b505f2a20bff962dfd28718327f61e25b09a9bc915f1dae7b1e534"
}
JSON
MANIFEST_OUT="$(UPDATE_MANIFEST_URL="file://$TMP_ROOT/version.json" repo_manifest)"
assert_eq "$MANIFEST_OUT" "https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.4.8/android-studio-xpro-linux.tar.gz 25c97ca6c6b505f2a20bff962dfd28718327f61e25b09a9bc915f1dae7b1e534 2026.1.4.8" \
    "repo_manifest extrae url, sha256 y version desde version.json"

# 9. check_update con PORTABLE_NO_UPDATE=1 no toca nada
PORTABLE_NO_UPDATE=1 check_update "$FAKE_BASE"
assert_eq "$?" "0" "con PORTABLE_NO_UPDATE=1 check_update retorna 0 sin red"

if summarize; then
    exit 0
else
    exit 1
fi