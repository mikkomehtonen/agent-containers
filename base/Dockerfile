FROM node:26-slim AS base

ARG TARGETARCH
# Combine all tools here. Note: added specific tools you listed for runtime
ARG LOCAL_TOOLS="git curl jq ripgrep vim nano make zip unzip ssh-client wget tree imagemagick ca-certificates gnupg procps build-essential python3 pipx golang"

# 1. Install System Dependencies (as root)
RUN apt-get update && \
  apt-get install -y --no-install-recommends ${LOCAL_TOOLS} && \
  rm -rf /var/lib/apt/lists/*

# Install also GH that is not in official apt source
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# Install Bun by copying from the official image
# This installs bun globally to /usr/local/bin so it is available to everyone
COPY --from=oven/bun:1 /usr/local/bin/bun /usr/local/bin/bun
# Create the bunx symlink (standard practice)
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# Install browser support for Playwright / agent-browser:
# - amd64: Playwright system libraries (both tools then download their
#   own browser builds below)
# - arm64: same, plus distro Chromium (agent-browser is pointed at it
#   via AGENT_BROWSER_EXECUTABLE_PATH in the base-arm64 stage below)
RUN npx playwright install-deps chromium && \
    if [ "$TARGETARCH" = "arm64" ]; then \
      apt-get update && \
      apt-get install -y --no-install-recommends chromium chromium-sandbox && \
      rm -rf /var/lib/apt/lists/*; \
    fi

# Corepack (no longer bundled with Node since v25, install manually)
RUN npm install -g corepack && corepack enable

# 2. Configure the existing 'node' user
# The node image usually creates the node user. We ensure it owns the app dir.
WORKDIR /app
RUN chown -R node:node /app

# 3. Switch to 'node' user for config setup
USER node

# 4. Configure NPM global location for the 'node' user
# This allows npm install -g without root permissions
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH

# Configure Bun global location for 'node' user ---
# This ensures 'bun install -g' works without root and saves to the user home
ENV BUN_INSTALL=/home/node/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

RUN mkdir -p /home/node/.npm-global && \
  mkdir -p /home/node/.config && \
  mkdir -p /home/node/.local && \
  mkdir -p /home/node/.bun/bin

# 5. Install agent-browser (headless browser automation CLI for AI agents)
# On amd64 this also downloads Chrome to the node user's cache.
# On arm64 no download happens: the base-arm64 stage below points
# agent-browser at the distro Chromium installed earlier.
RUN npm install -g agent-browser && \
    if [ "$TARGETARCH" != "arm64" ]; then agent-browser install; fi

# Install Playwright + its Chromium. Works on both architectures:
# Playwright always uses its own downloaded builds from the node user's
# cache (it cannot point at the distro Chromium on arm64), and the
# required system libraries were installed at the top of this file.
RUN npm install -g playwright && npx playwright install chromium

# 6. Bash Configuration
# Add the path export to bashrc so interactive shells pick it up
RUN echo "export PATH=${NPM_CONFIG_PREFIX}/bin:${BUN_INSTALL}/bin:\$PATH" >> /home/node/.bashrc

# 7. Copy config files to the 'node' user's home
COPY --chown=node:node ./.bash_aliases /home/node/.bash_aliases
# Global pnpm config (see pnpm-config.yaml for rationale)
COPY --chown=node:node ./pnpm-config.yaml /home/node/.config/pnpm/config.yaml
RUN echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> /home/node/.bashrc

# 8. Per-architecture final stages.
# Dockerfile ENV cannot be conditional, so the only arch-specific config
# (which browser agent-browser should use) is split into final stages.
# The Makefile builds the stage matching the host architecture; for manual
# builds pass --target=base-arm64 on arm64 hosts.
#
# agent-browser honours AGENT_BROWSER_EXECUTABLE_PATH (it ignores the
# PLAYWRIGHT_* variables), and only on arm64 the distro Chromium at
# /usr/bin/chromium is the designated browser.
FROM base AS base-amd64

CMD ["/bin/bash"]

FROM base AS base-arm64

ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium

CMD ["/bin/bash"]
