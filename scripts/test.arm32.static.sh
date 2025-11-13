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
ARMHF_NAME="$(basename "${ARMHF_BIN}")"
ARMEL_NAME="$(basename "${ARMEL_BIN}")"

ABS_ARTIFACT_DIR="$(cd "${ARTIFACT_DIR}" && pwd)"

echo "Running put/ls/get smoke test for hard-float binary (arm/v7)..."
docker run --rm \
    --platform linux/arm/v7 \
    -v "${ABS_ARTIFACT_DIR}:/artifacts:ro" \
    debian:bookworm-slim bash -c 'set -euo pipefail; \
      printf "test-armhf" > /tmp/payload.txt; \
      /artifacts/'"${ARMHF_NAME}"' put /tmp/payload.txt smb://ci@samba-test/ci/ci_armhf_upload.txt;\
      /artifacts/'"${ARMHF_NAME}"' ls smb://ci@samba-test/ci;\
      /artifacts/'"${ARMHF_NAME}"' get smb://ci@samba-test/ci/ci_armhf_upload.txt /tmp/payload_out.txt;\
      diff -u /tmp/payload.txt /tmp/payload_out.txt'

echo
echo "Running put/ls/get smoke test for soft-float binary (arm/v5)..."
docker run --rm \
    --platform linux/arm/v5 \
    -v "${ABS_ARTIFACT_DIR}:/artifacts:ro" \
    debian:bookworm-slim bash -c 'set -euo pipefail;\
      printf "test-armel" > /tmp/payload.txt;\
      /artifacts/'"${ARMEL_NAME}"' put /tmp/payload.txt smb://ci@samba-test/ci/ci_armel_upload.txt;\
      /artifacts/'"${ARMEL_NAME}"' ls smb://ci@samba-test/ci;\
      /artifacts/'"${ARMEL_NAME}"' get smb://ci@samba-test/ci/ci_armel_upload.txt /tmp/payload_out.txt;\
      diff -u /tmp/payload.txt /tmp/payload_out.txt'

echo
echo "Completed emulated smoke tests."
