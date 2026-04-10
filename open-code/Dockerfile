# Build stage
FROM agent-base AS builder

# 1. Install global modules
RUN npm install -g opencode-ai && \
  npm install -g @anthropic-ai/claude-code && \
  echo "Installed Open Code version: $(opencode --version)"

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
COPY --from=builder --chown=node:node /home/node/.npm-global /home/node/.npm-global

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   OPEN CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && opencode --version && \
  echo "\e[0m" && \
  echo ""

CMD ["opencode"]
