# muslcc-builder base image

Utility image that installs the musl.cc cross toolchains (armhf/armel) plus the common build prerequisites (cmake, ninja, etc.). Build it once and reuse across Dockerfiles to avoid re-downloading toolchains.

## Build

Copy `.env.example` to `.env`, adjust `IMAGE_NAME`, `TAG`, and `PLATFORMS` if necessary, then:
```bash
cd docker/muslcc-builder
make          # builds the first platform locally (default linux/amd64 via buildx)
# make push   # pushes a multi-arch image (default linux/amd64 + linux/arm64)
```

## Use

In other Dockerfiles:

After pushing, other Dockerfiles (like `Dockerfile.arm32`) can simply
`FROM flozano/bookworm-muslcc-build:latest AS builder` and run `./scripts/build.arm32.static.sh`;
the `ARM32_TOOLCHAINS` env var is already defined by the base image.

The base image sets:
- `TOOLCHAIN_ROOT=/opt/muslcc`
- `PATH` to include both armhf/armel musl toolchain binaries
- `ARM32_TOOLCHAINS` with the paths expected by `scripts/build.arm32.static.sh`

Rebuild/push the base image if you need newer musl toolchains or extra packages (edit the Dockerfile and rebuild).***
