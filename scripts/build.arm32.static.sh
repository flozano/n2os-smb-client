#!/usr/bin/env bash
set -euo pipefail

KRB_IMPL="${KRB_IMPL:-NONE}"
if [[ "${KRB_IMPL}" != "NONE" && "${KRB_IMPL}" != "MIT" ]]; then
    echo "Static ARM32 build supports KRB_IMPL=NONE or KRB_IMPL=MIT (current: ${KRB_IMPL})." >&2
    exit 1
fi

ARTIFACT_DIR="${ARTIFACT_DIR:-/artifacts}"
mkdir -p "${ARTIFACT_DIR}"

triplets=(arm-linux-gnueabihf arm-linux-gnueabi)
suffixes=(armhf armel)

for idx in "${!triplets[@]}"; do
    triplet="${triplets[$idx]}"
    suffix="${suffixes[$idx]}"
    build_dir="build_${suffix}_static"
    sysroot="/usr/${triplet}"

    cmake -S . -B "${build_dir}" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DKRB_IMPL="${KRB_IMPL}" \
        -DENABLE_STATIC_LINKING=ON \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=arm \
        -DCMAKE_SYSROOT="${sysroot}" \
        -DCMAKE_C_COMPILER="${triplet}-gcc" \
        -DCMAKE_CXX_COMPILER="${triplet}-g++" \
        -DCMAKE_FIND_ROOT_PATH="${sysroot}" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc" \
        -DCMAKE_BUILD_RPATH="" \
        -DCMAKE_INSTALL_RPATH=""

    cmake --build "${build_dir}" --target n2os_smb_client --parallel

    "${triplet}-strip" "${build_dir}/n2os_smb_client"
    out_name="n2os_smb_client.linux_${suffix}_static"
    if [[ "${KRB_IMPL}" != "NONE" ]]; then
        out_name="n2os_smb_client.linux_${suffix}_static_${KRB_IMPL,,}"
    fi
    cp "${build_dir}/n2os_smb_client" \
        "${ARTIFACT_DIR}/${out_name}"
done
