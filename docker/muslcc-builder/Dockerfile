# syntax=docker/dockerfile:1.5
#
# Base image that installs the musl cross toolchains and common build tools.
# Usage:
#   docker build -f docker/muslcc-builder/Dockerfile -t muslcc-builder .
#   # Then in other Dockerfiles:
#   #   FROM muslcc-builder AS builder

ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

ARG MUSL_TOOLCHAINS="arm-linux-musleabihf-cross arm-linux-musleabi-cross"

ENV DEBIAN_FRONTEND=noninteractive \
    TOOLCHAIN_ROOT=/opt/muslcc

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    build-essential \
    ninja-build \
    cmake \
    pkg-config \
    python3 \
    file \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -euo pipefail; \
    mkdir -p "${TOOLCHAIN_ROOT}"; \
    for tc in ${MUSL_TOOLCHAINS}; do \
        curl -fsSL "https://musl.cc/${tc}.tgz" | tar -xz -C "${TOOLCHAIN_ROOT}"; \
    done

ENV PATH="${TOOLCHAIN_ROOT}/arm-linux-musleabihf-cross/bin:${TOOLCHAIN_ROOT}/arm-linux-musleabi-cross/bin:${PATH}" \
    ARM32_TOOLCHAINS="armhf:arm-linux-musleabihf:${TOOLCHAIN_ROOT}/arm-linux-musleabihf-cross armel:arm-linux-musleabi:${TOOLCHAIN_ROOT}/arm-linux-musleabi-cross"
