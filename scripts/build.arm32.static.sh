#!/usr/bin/env bash
set -euo pipefail

KRB_IMPL="${KRB_IMPL:-NONE}"
if [[ "${KRB_IMPL}" != "NONE" ]]; then
    echo "Musl-based static ARM32 build currently supports only KRB_IMPL=NONE." >&2
    exit 1
fi

ARTIFACT_DIR="${ARTIFACT_DIR:-/artifacts}"
mkdir -p "${ARTIFACT_DIR}"

TOOLCHAINS=(
    "armhf:arm-linux-musleabihf:/opt/arm-linux-musleabihf-cross"
    "armel:arm-linux-musleabi:/opt/arm-linux-musleabi-cross"
)

for entry in "${TOOLCHAINS[@]}"; do
    IFS=":" read -r suffix triplet root <<< "${entry}"
    build_dir="build_${suffix}_static"
    cc="${root}/bin/${triplet}-gcc"
    cxx="${root}/bin/${triplet}-g++"
    ar_bin="${root}/bin/${triplet}-ar"
    ranlib_bin="${root}/bin/${triplet}-ranlib"
    strip_bin="${root}/bin/${triplet}-strip"
    sysroot="${root}/${triplet}"

    if [[ ! -x "${cc}" ]]; then
        echo "Missing compiler ${cc}. Ensure musl toolchains are available in ${root}." >&2
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
        -DCMAKE_EXE_LINKER_FLAGS="-static" \
        -DCMAKE_BUILD_RPATH="" \
        -DCMAKE_INSTALL_RPATH=""

    cmake --build "${build_dir}" --target n2os_smb_client --parallel

    "${strip_bin}" "${build_dir}/n2os_smb_client"
    cp "${build_dir}/n2os_smb_client" \
        "${ARTIFACT_DIR}/n2os_smb_client.linux_${suffix}_static_musl"
done
