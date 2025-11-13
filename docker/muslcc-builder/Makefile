include .env

IMAGE ?= $(IMAGE_NAME):$(TAG)
PLATFORMS ?= $(PLATFORMS)
PLATFORMS ?= linux/amd64,linux/arm64
LOAD_PLATFORM := $(firstword $(subst ',', ,$(PLATFORMS)))
BUILD_ARGS ?=
BUILDX ?= docker buildx

.PHONY: all build push login

all: build

.env:
	cp .env.example .env

ensure-builder:
	@$(BUILDX) ls >/dev/null

build: .env ensure-builder
	$(BUILDX) build $(BUILD_ARGS) --platform $(LOAD_PLATFORM) -f Dockerfile -t $(IMAGE) --load .

push: .env ensure-builder
	$(BUILDX) build $(BUILD_ARGS) --platform $(PLATFORMS) -f Dockerfile -t $(IMAGE) --push .

login:
	@echo "Run 'docker login $(REGISTRY)' if required before pushing."
