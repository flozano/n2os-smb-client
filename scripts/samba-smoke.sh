#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_DIR="${1:-arm32-static}"
SMB_PASSWORD="${SMB_PASSWORD:-CiPassword123_}"
NET_NAME="${NET_NAME:-smb-ci-local}"
SHARE_DIR="${SHARE_DIR:-$(pwd)/ci_share}"
CONTAINER_NAME="${CONTAINER_NAME:-samba-test}"
SMB_CONF_PATH="${SMB_CONF_PATH:-$(pwd)/smb.conf}"

mkdir -p "${SHARE_DIR}"
chmod 777 "${SHARE_DIR}"

if [[ ! -f "${SMB_CONF_PATH}" ]]; then
  echo "Missing smb.conf at ${SMB_CONF_PATH}" >&2
  exit 1
fi

CREATED_NET=0
if ! docker network inspect "${NET_NAME}" >/dev/null 2>&1; then
  docker network create "${NET_NAME}" >/dev/null
  CREATED_NET=1
fi

cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  if [[ "${CREATED_NET}" -eq 1 ]]; then
    docker network rm "${NET_NAME}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d --name "${CONTAINER_NAME}" --network "${NET_NAME}" \
  -h samba-test \
  -v "${SHARE_DIR}:/share" \
  -v "${SMB_CONF_PATH}:/etc/samba/smb.conf:ro" \
  dperson/samba -S -u "ci;${SMB_PASSWORD}" >/dev/null

sleep 10

SMB_SHARE="smb://ci@samba-test/ci" \
SMB_PASSWORD="${SMB_PASSWORD}" \
DOCKER_NETWORK="${NET_NAME}" \
./scripts/test.arm32.static.sh "${ARTIFACT_DIR}"

echo "Local Samba smoke test completed."
