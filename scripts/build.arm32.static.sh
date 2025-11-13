#!/usr/bin/env bash
set -euo pipefail

KRB_IMPL="${KRB_IMPL:-NONE}"
if [[ "${KRB_IMPL}" != "NONE" ]]; then
    echo "Musl-based static ARM32 build currently supports only KRB_IMPL=NONE." >&2
    exit 1
fi

ARTIFACT_DIR="${ARTIFACT_DIR:-/artifacts}"
mkdir -p "${ARTIFACT_DIR}"

DEFAULT_TOOLCHAINS=(
    "armhf:arm-linux-musleabihf:/opt/arm-linux-musleabihf-cross"
    "armel:arm-linux-musleabi:/opt/arm-linux-musleabi-cross"
)

if [[ -n "${ARM32_TOOLCHAINS:-}" ]]; then
    IFS=' ' read -r -a TOOLCHAINS <<< "${ARM32_TOOLCHAINS}"
else
    TOOLCHAINS=("${DEFAULT_TOOLCHAINS[@]}")
fi

find_tool() {
    local root="$1"
    local triplet="$2"
    local tool="$3"
    local resolved
    if resolved=$(command -v "${triplet}-${tool}" 2>/dev/null); then
        echo "${resolved}"
        return 0
    fi
    local search_dirs=(
        "${root}"
        "${root}/bin"
        "${root}/usr/bin"
        "${root}/usr/local/bin"
        "${root}/${triplet}"
        "${root}/${triplet}/bin"
        "${root}/sbin"
        "${root}/usr/sbin"
    )
    local candidate
    for dir in "${search_dirs[@]}"; do
        candidate="${dir}/${triplet}-${tool}"
        if [[ -x "${candidate}" ]]; then
            echo "${candidate}"
            return 0
        fi
    done
    candidate=$(find "${root}" -type f -name "${triplet}-${tool}" -perm /111 2>/dev/null | head -n 1)
    if [[ -n "${candidate}" ]]; then
        echo "${candidate}"
        return 0
    fi
    return 1
}

for entry in "${TOOLCHAINS[@]}"; do
    IFS=":" read -r suffix triplet root <<< "${entry}"
    build_dir="build_${suffix}_static"

    cc=$(find_tool "${root}" "${triplet}" "gcc") || {
        echo "Missing compiler for ${triplet} under ${root}" >&2
        exit 1
    }
    if ! cxx=$(find_tool "${root}" "${triplet}" "g++"); then
        cxx="${cc%gcc}g++"
    fi
    ar_bin=$(find_tool "${root}" "${triplet}" "ar") || {
        echo "Missing ar for ${triplet}" >&2
        exit 1
    }
    ranlib_bin=$(find_tool "${root}" "${triplet}" "ranlib") || {
        echo "Missing ranlib for ${triplet}" >&2
        exit 1
    }
    strip_bin=$(find_tool "${root}" "${triplet}" "strip") || {
        echo "Missing strip for ${triplet}" >&2
        exit 1
    }

    if [[ -d "${root}/${triplet}" ]]; then
        sysroot="${root}/${triplet}"
    elif [[ -d "${root}" ]]; then
        sysroot="${root}"
    else
        sysroot="$(dirname "$(dirname "${cc}")")/${triplet}"
    fi
    if [[ ! -d "${sysroot}" && -d "$(dirname "${cc}")/../${triplet}" ]]; then
        sysroot="$(dirname "${cc}")/../${triplet}"
    fi
    if [[ ! -d "${sysroot}" ]]; then
        echo "Sysroot not found for ${triplet} within ${root}" >&2
        exit 1
    fi

    cmake -S . -B "${build_dir}" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DKRB_IMPL="${KRB_IMPL}" \
        -DENABLE_STATIC_LINKING=ON \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=arm \
        -DCMAKE_SYSROOT="${sysroot}" \
        -DCMAKE_C_COMPILER="${cc}" \
        -DCMAKE_CXX_COMPILER="${cxx}" \
        -DCMAKE_AR="${ar_bin}" \
        -DCMAKE_RANLIB="${ranlib_bin}" \
        -DCMAKE_FIND_ROOT_PATH="${sysroot}" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DHAVE_ARC4RANDOM=0 \
        -DHAVE_ARC4RANDOM_BUF=0 \
        -DCMAKE_EXE_LINKER_FLAGS="-static" \
        -DCMAKE_BUILD_RPATH="" \
        -DCMAKE_INSTALL_RPATH=""

    cmake --build "${build_dir}" --target n2os_smb_client --parallel

    "${strip_bin}" "${build_dir}/n2os_smb_client"
    cp "${build_dir}/n2os_smb_client" \
        "${ARTIFACT_DIR}/n2os_smb_client.linux_${suffix}_static_musl"
done
