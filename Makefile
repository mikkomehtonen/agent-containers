.PHONY: all clean deep-clean base claude-code openai-codex open-code

# Determine container engine (podman or docker)
CONTAINER_ENGINE := $(shell which podman 2>/dev/null || which docker 2>/dev/null)

# Base image target: the base Dockerfile has per-architecture final stages
# (base-amd64 / base-arm64), pick the one matching the build host
HOST_ARCH := $(shell uname -m)
ifeq ($(HOST_ARCH),aarch64)
  BASE_TARGET := base-arm64
else
  BASE_TARGET := base-amd64
endif

# Tools to install in to the containers with apt-get
LOCAL_TOOLS := "git curl jq ripgrep joe nano make zip unzip ssh-client wget tree imagemagick build-essential python3 python3-pip python3-venv python-is-python3 pipx golang"

OPENCODE_VERSION ?= 1.18.21
PECK_VERSION ?= 0.3.4
OPENCODE_CANDIDATE_VERSION ?= latest

# Ensure we have a container engine
ifeq ($(CONTAINER_ENGINE),)
$(error No container engine (podman/docker) found in PATH)
endif

all: base claude-code openai-codex

base:
	@echo "Building base image ($(BASE_TARGET))"
	$(CONTAINER_ENGINE) build \
		--target=$(BASE_TARGET) \
		--build-arg LOCAL_TOOLS=$(LOCAL_TOOLS) \
		-t agent-base \
		-f base/Dockerfile base

claude-code: base
	@echo "Building claude-code"
	$(CONTAINER_ENGINE) build \
		--no-cache \
		-t claude-code \
		-f claude-code/Dockerfile claude-code

openai-codex: base
	@echo "Building openai-codex"
	$(CONTAINER_ENGINE) build \
		--no-cache \
		-t openai-codex \
		-f openai-codex/Dockerfile openai-codex

open-code: base
	@echo "Building open-code"
	$(CONTAINER_ENGINE) build \
		--no-cache \
		--build-arg OPENCODE_VERSION=$(OPENCODE_VERSION) \
		--build-arg PECK_VERSION=${PECK_VERSION} \
		-t open-code \
		-f open-code/Dockerfile open-code

open-code-candidate: base
	@echo "Building candidate open-code $(OPENCODE_CANDIDATE_VERSION)"
	$(CONTAINER_ENGINE) build \
		--no-cache \
		--build-arg OPENCODE_VERSION=$(OPENCODE_CANDIDATE_VERSION) \
		--build-arg PECK_VERSION=${PECK_VERSION} \
		-t open-code:candidate \
		-f open-code/Dockerfile open-code

clean:
	@echo "Removing container images"
	@for image in open-code claude-code openai-codex agent-base; do \
		if $(CONTAINER_ENGINE) image inspect $$image > /dev/null 2>&1; then \
			echo "Removing $$image"; \
			$(CONTAINER_ENGINE) rmi -f $$image; \
		else \
			echo "Image $$image does not exist, skipping"; \
		fi; \
	done

deep-clean: clean
	@echo "Pruning container build cache"
	-$(CONTAINER_ENGINE) build prune --force
