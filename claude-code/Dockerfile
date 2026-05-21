# Build stage
FROM agent-base AS builder

# Install build dependencies and Claude Code
RUN npm install -g @anthropic-ai/claude-code && \
  echo "Installed Claude Code version: $(claude --version)"

RUN npm install -g typescript typescript-language-server
# Runtime stage
FROM agent-base

# Copy the installed Claude Code + TS language server from builder
COPY --from=builder --chown=node:node /home/node/.npm-global /home/node/.npm-global

ENV CLAUDE_CODE_PLUGIN_CACHE_DIR=/home/node/.claude-plugins
RUN mkdir -p /home/node/.claude-plugins
RUN claude plugin install typescript-lsp@claude-plugins-official && \
    claude plugin install github@claude-plugins-official && \
    claude plugin install atlassian@claude-plugins-official && \
    claude plugin install figma@claude-plugins-official && \
    claude plugin install commit-commands@claude-plugins-official \
    || echo "Plugin pre-population skipped (no auth). Install manually with /plugin."
ENV CLAUDE_CODE_PLUGIN_SEED_DIR=/home/node/.claude-plugins

ENV NX_DAEMON=false

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   CLAUDE CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && claude --version && \
  echo "\e[0m" && \
  echo ""

# ┌─────────────────────────────────────────────────────────────┐
# │ --dangerously-skip-permissions: no approval prompts.        │
# │ Safe in an isolated container.                              │
# └─────────────────────────────────────────────────────────────┘
CMD ["claude", "--dangerously-skip-permissions"]
