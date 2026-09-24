#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ALL_FAIL=0

for t in blackbox_setup.test.sh blackbox_launcher.test.sh blackbox_uninstall.test.sh whitebox_content.test.sh blackbox_update.test.sh; do
    printf "\n>>> %s\n" "$t"
    if bash "$SCRIPT_DIR/$t"; then
        :
    else
        RUN_ALL_FAIL=1
    fi
done

printf "\n== Suites: %s ==\n" "$([ "$RUN_ALL_FAIL" -eq 0 ] && echo "PASS" || echo "FAIL")"
exit "$RUN_ALL_FAIL"