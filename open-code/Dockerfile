ARG OPENCODE_VERSION=1.18.21
ARG PECK_VERSION=0.3.4

# Build stage
FROM agent-base AS builder

ARG OPENCODE_VERSION
ARG PECK_VERSION

# 1. Install global modules
RUN npm install -g opencode-ai@${OPENCODE_VERSION} && \
  echo "Installed Open Code version: $(opencode --version)"

RUN git clone --depth 1 --branch v${PECK_VERSION} https://github.com/mikkomehtonen/peck.git /tmp/peck && \
    cd /tmp/peck && \
    npm ci && \
    npm run build && \
    npm pack && \
    npm install -g /tmp/peck/peck-cli-${PECK_VERSION}.tgz && \
    peck --version && \
    rm -rf /tmp/peck

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
COPY --from=builder --chown=node:node /home/node/.npm-global /home/node/.npm-global

USER root
RUN ln -sf /home/node/.npm-global/bin/peck /usr/local/bin/peck

ENV PIPX_HOME="/opt/pipx"
ENV PIPX_BIN_DIR="/usr/local/bin"
RUN pipx install graphifyy

USER node

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   OPEN CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && opencode --version && \
  echo "\e[0m" && \
  echo ""

CMD ["opencode"]
