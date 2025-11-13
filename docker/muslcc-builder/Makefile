include .env

IMAGE ?= $(IMAGE_NAME):$(TAG)
BUILD_PLATFORM ?= $(PLATFORM)
BUILD_PLATFORM ?= linux/amd64
BUILD_ARGS ?=
BUILDX ?= docker buildx

.PHONY: all build push login

all: build

.env:
	cp .env.example .env

ensure-builder:
	@$(BUILDX) ls >/dev/null

build: .env ensure-builder
	$(BUILDX) build $(BUILD_ARGS) --platform $(BUILD_PLATFORM) -f Dockerfile -t $(IMAGE) --load .

push: .env ensure-builder
	$(BUILDX) build $(BUILD_ARGS) --platform $(BUILD_PLATFORM) -f Dockerfile -t $(IMAGE) --push .

login:
	@echo "Run 'docker login $(REGISTRY)' if required before pushing."
