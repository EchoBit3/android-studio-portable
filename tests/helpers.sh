#!/usr/bin/env bash

PASS_COUNT=0
FAIL_COUNT=0

assert_eq() {
    local actual="$1"
    local expected="$2"
    local msg="$3"
    if [ "$actual" = "$expected" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        printf "  ok - %s\n" "$msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf "  FAIL - %s\n    expected: [%s]\n    actual:   [%s]\n" "$msg" "$expected" "$actual"
    fi
}

assert_true() {
    local cond="$1"
    local msg="$2"
    if eval "$cond"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        printf "  ok - %s\n" "$msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf "  FAIL - %s\n    cond: [%s]\n" "$msg" "$cond"
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="$2"
    if [ -e "$file" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        printf "  ok - %s\n" "$msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf "  FAIL - %s\n    file: [%s] no existe\n" "$msg" "$file"
    fi
}

assert_symlink() {
    local target="$1"
    local link="$2"
    local msg="$3"
    if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        printf "  ok - %s\n" "$msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf "  FAIL - %s\n    link: [%s] -> [%s], esperado [%s]\n" "$msg" "$link" "$(readlink "$link" 2>/dev/null)" "$target"
    fi
}

summarize() {
    printf "\n== Resultado: %d ok, %d FAIL ==\n" "$PASS_COUNT" "$FAIL_COUNT"
    if [ "$FAIL_COUNT" -gt 0 ]; then
        return 1
    fi
    return 0
}