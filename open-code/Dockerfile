# Build stage
FROM agent-base AS builder

# 1. Install global modules
RUN npm install -g opencode-ai && \
  echo "Installed Open Code version: $(opencode --version)"

RUN git clone --depth 1 --branch v0.3.0 https://github.com/mikkomehtonen/peck.git /tmp/peck && \
    cd /tmp/peck && \
    npm ci && \
    npm run build && \
    npm pack && \
    npm install -g /tmp/peck/peck-cli-0.3.0.tgz && \
    peck --version && \
    rm -rf /tmp/peck

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
COPY --from=builder --chown=node:node /home/node/.npm-global /home/node/.npm-global

USER root
RUN ln -sf /home/node/.npm-global/bin/peck /usr/local/bin/peck
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
