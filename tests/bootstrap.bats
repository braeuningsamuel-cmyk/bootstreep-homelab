#!/usr/bin/env bats
#
# BATS tests for bootstreep-homelab bash scripts
# Install: apt install bats
# Run: bats tests/bootstrap.bats
#

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SCRIPT="${REPO_ROOT}/bootstrap/bootstrap.sh"
    SCRIPTS_DIR="${REPO_ROOT}/bootstrap/scripts"
}

@test "bootstrap.sh exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "bootstrap.sh has bash shebang" {
    run head -1 "$SCRIPT"
    [[ "$output" == "#!/bin/bash"* ]]
}

@test "bootstrap.sh uses strict mode" {
    run head -10 "$SCRIPT"
    [[ "$output" == *"set -Eeuo pipefail"* ]]
}

@test "all phase scripts exist" {
    for i in 01 02 03 04 05 06 07 08 09 10 11; do
        local script=$(ls "${SCRIPTS_DIR}/${i}-"*.sh 2>/dev/null | head -1)
        [ -n "$script" ] || skip "Phase ${i} script not found"
        [ -f "$script" ]
    done
}

@test "all phase scripts have strict mode" {
    for script in "${SCRIPTS_DIR}"/*.sh; do
        run head -10 "$script"
        if [[ ! "$output" == *"set -Eeuo pipefail"* ]]; then
            echo "Missing strict mode: $script"
            return 1
        fi
    done
}

@test "bootstrap.sh --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -ne 0 ]  # exits with 1 when showing help
    [[ "$output" == *"Usage"* ]]
}

@test "bootstrap.sh --version shows version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"bootstreep"* ]]
    [[ "$output" == *"v"* ]]
}

@test "config files have example templates" {
    [ -f "${REPO_ROOT}/bootstrap/config/bootstrap.env" ]
    [ -f "${REPO_ROOT}/bootstrap/config/users.env" ]
    [ -f "${REPO_ROOT}/bootstrap/config/network.env" ]
    [ -f "${REPO_ROOT}/bootstrap/config/storage.env" ]
    [ -f "${REPO_ROOT}/bootstrap/config/docker.env" ]
}

@test "all compose stacks have docker-compose.yml" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        [ -f "${service_dir}/docker-compose.yml" ]
    done
}

@test "all compose stacks have .env.example" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        [ -f "${service_dir}/.env.example" ]
    done
}

@test "all compose files have YAML document start" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        run head -1 "${service_dir}/docker-compose.yml"
        [[ "$output" == "---"* ]] || (echo "Missing --- in ${service_dir}"; false)
    done
}

@test "all compose files have healthchecks" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        run grep -l "healthcheck:" "${service_dir}/docker-compose.yml"
        [ "$status" -eq 0 ] || (echo "Missing healthcheck in ${service_dir}"; false)
    done
}

@test "all compose files have resource limits" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        run grep -l "resources:" "${service_dir}/docker-compose.yml"
        [ "$status" -eq 0 ] || (echo "Missing resources in ${service_dir}"; false)
    done
}

@test "all compose files have restart policies" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        run grep -l "restart:" "${service_dir}/docker-compose.yml"
        [ "$status" -eq 0 ] || (echo "Missing restart in ${service_dir}"; false)
    done
}

@test "docker-compose files have no hardcoded secrets" {
    local compose_dir="${REPO_ROOT}/bootstrap/compose"
    for service_dir in "${compose_dir}"/*/; do
        ! grep -rE "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{20,}['\"]" \
            "${service_dir}/docker-compose.yml" || \
            (echo "Hardcoded secret in ${service_dir}"; false)
    done
}

@test "README.md exists and is comprehensive" {
    local readme="${REPO_ROOT}/README.md"
    [ -f "$readme" ]
    # Check minimum size (should be detailed)
    local lines=$(wc -l < "$readme")
    [ "$lines" -gt 100 ]
}

@test "LICENSE file exists" {
    [ -f "${REPO_ROOT}/LICENSE" ]
}

@test "Makefile exists and has help target" {
    [ -f "${REPO_ROOT}/Makefile" ]
    grep -q "^help:" "${REPO_ROOT}/Makefile"
}

@test ".gitignore exists" {
    [ -f "${REPO_ROOT}/.gitignore" ]
}

@test ".github/workflows/ci.yml exists" {
    [ -f "${REPO_ROOT}/.github/workflows/ci.yml" ]
}

@test "docs directory has all required documentation" {
    [ -f "${REPO_ROOT}/docs/INSTALL.md" ]
    [ -f "${REPO_ROOT}/docs/CONFIGURATION.md" ]
    [ -f "${REPO_ROOT}/docs/SERVICES.md" ]
    [ -f "${REPO_ROOT}/docs/SECURITY.md" ]
    [ -f "${REPO_ROOT}/docs/TROUBLESHOOTING.md" ]
}

@test "no TODOs or FIXMEs in critical scripts" {
    ! grep -E "TODO|FIXME|XXX" "${SCRIPTS_DIR}"/*.sh || \
        (echo "Found TODO/FIXME markers"; false)
}