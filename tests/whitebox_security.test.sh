#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

printf '== Caja blanca: seguridad y calidad ==\n'

# 1. Dependabot activo contra el único ecosistema con dependencias (GitHub Actions)
assert_file_exists "$REPO_DIR/.github/dependabot.yml" "existe config de Dependabot"
assert_true "grep -q 'github-actions' '$REPO_DIR/.github/dependabot.yml'" \
    "Dependabot rastrea el ecosistema github-actions"
assert_true "grep -q 'weekly' '$REPO_DIR/.github/dependabot.yml'" \
    "Dependabot corre con periodicidad semanal"

# 2. Code scanning de bash presente (ShellCheck, no CodeQL: no analiza shell)
assert_file_exists "$REPO_DIR/.github/workflows/code-scan.yml" "existe workflow de code scanning"
assert_true "grep -q 'shellcheck-scan' '$REPO_DIR/.github/workflows/code-scan.yml'" \
    "el code scanning usa ShellCheck SARIF"
assert_true "grep -q 'security-events: write' '$REPO_DIR/.github/workflows/code-scan.yml'" \
    "el workflow tiene permiso para subir resultados SARIF"

# 3. El CI ejecuta todas las suites definidas aquí
assert_file_exists "$REPO_DIR/.github/workflows/ci.yml" "existe workflow de CI"
assert_true "grep -q 'tests/run-tests.sh' '$REPO_DIR/.github/workflows/ci.yml'" \
    "el CI ejecuta la batería de pruebas del repo"

# 4. Guardas de seguridad en el código fuente
assert_true "grep -q -- '--no-same-owner' '$REPO_DIR/setup.sh'" \
    "setup.sh extrae sin conservar propietarios del tar"
assert_true "grep -q 'tar -tzf' '$REPO_DIR/setup.sh'" \
    "setup.sh inspecciona el tar antes de extraer"
assert_true "grep -q 'sha256sum' '$REPO_DIR/src/lib-portable.sh'" \
    "lib-portable verifica el sha256 del update"

# 5. Sin secretos ni credenciales en el repo
if command -v git >/dev/null 2>&1; then
    leaked="$(git -C "$REPO_DIR" grep -lE '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' -- ':!tests' 2>/dev/null || true)"
    [ -z "$leaked" ]
    res=$?
    assert_true "[ '$res' -eq 0 ]" "el árbol no contiene tokens ni claves privadas"
fi

# 6. La versión instalable se expone en .studio-version (base para el QA de versionado)
assert_file_exists "$REPO_DIR/version.json" "existe el manifest de versión de respaldo"
assert_true "grep -Eq '\"version\"\\s*:\\s*\"[0-9]+\\.' '$REPO_DIR/version.json'" \
    "version.json declara una versión con formato numérico"

if summarize; then
    exit 0
else
    exit 1
fi