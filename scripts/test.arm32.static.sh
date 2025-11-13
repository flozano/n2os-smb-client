#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_DIR="${1:-arm32-static}"

if [[ -d "${ARTIFACT_DIR}/artifacts" ]]; then
    ARTIFACT_DIR="${ARTIFACT_DIR}/artifacts"
fi

if [[ ! -d "${ARTIFACT_DIR}" ]]; then
    echo "Artifact directory '${ARTIFACT_DIR}' not found. Pass the path as the first argument." >&2
    exit 1
fi

# shellcheck disable=SC2120
find_binary() {
    local base="$1"
    local dir="$2"
    local fallback
    for candidate in "${base}" "${base}_musl"; do
        if [[ -f "${dir}/${candidate}" ]]; then
            echo "${dir}/${candidate}"
            return 0
        fi
    done
    echo "Missing binary: ${dir}/${base}[ _mit|_heimdal ]" >&2
    exit 1
}

ARMHF_BIN="$(find_binary "n2os_smb_client.linux_armhf_static" "${ARTIFACT_DIR}")"
ARMEL_BIN="$(find_binary "n2os_smb_client.linux_armel_static" "${ARTIFACT_DIR}")"

ABS_ARTIFACT_DIR="$(cd "${ARTIFACT_DIR}" && pwd)"

echo "Running --help for hard-float binary via linux/arm/v7 container..."
docker run --rm \
    --platform linux/arm/v7 \
    -v "${ABS_ARTIFACT_DIR}:/artifacts:ro" \
    debian:bookworm-slim \
    /artifacts/n2os_smb_client.linux_armhf_static --help >/tmp/armhf_help.txt
cat /tmp/armhf_help.txt

echo
echo "Running --help for soft-float binary via linux/arm/v5 container..."
docker run --rm \
    --platform linux/arm/v5 \
    -v "${ABS_ARTIFACT_DIR}:/artifacts:ro" \
    debian:bookworm-slim \
    /artifacts/n2os_smb_client.linux_armel_static --help >/tmp/armel_help.txt
cat /tmp/armel_help.txt

echo
echo "Completed emulated smoke tests."
