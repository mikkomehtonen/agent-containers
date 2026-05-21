# Claude Code Docker launcher — supports concurrent sessions
# Add to ~/.zshrc or source from ~/.config/zsh/functions/

# Persistent auth directory on the host.
# One-time setup writes here; every session reads from it.
CC_AUTH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code-auth"

# ── One-time setup ──────────────────────────────────────────────
# Run this once to authenticate everything interactively:
#   - Claude Code OAuth login
#   - gh auth login
#   - Plugin OAuth flows (Atlassian, Figma, etc.)
#
# Everything persists to CC_AUTH_DIR on your host.
cc_setup() {
  mkdir -p "$CC_AUTH_DIR"
  mkdir -p "$CC_AUTH_DIR/claude-home"
  touch "$CC_AUTH_DIR/claude.json"
  mkdir -p "$HOME/.config/gh"

  echo "Starting interactive setup session..."
  echo "Inside the container, run:"
  echo "  1. Claude will prompt for OAuth login on first start"
  echo "  2. gh auth login"
  echo "  3. /plugin — check Errors tab for any auth issues"
  echo ""

  command docker run --rm -it \
    --name "cc-setup" \
    --add-host=host.docker.internal:host-gateway \
    \
    -v "$CC_AUTH_DIR/claude-home:/home/node/.claude" \
    -v "$CC_AUTH_DIR/claude.json:/home/node/.claude.json" \
    -v "$HOME/.config/gh:/home/node/.config/gh" \
    -v "$PWD:/app:rw" \
    \
    -w /app \
    claude-code "$@"

  echo ""
  echo "Auth saved to $CC_AUTH_DIR"
  echo "Run 'cc' to start normal sessions."
}

# ── Normal session ──────────────────────────────────────────────
claude_code_docker() {
  # Verify auth exists
  if [[ ! -d "$CC_AUTH_DIR" ]] || [[ -z "$(ls -A "$CC_AUTH_DIR" 2>/dev/null)" ]]; then
    echo "No auth found. Run 'cc_setup' first."
    return 1
  fi

  local session_id="cc-${PWD:t}-$(date +%s | tail -c6)"
  local session_dir="${TMPDIR:-/tmp}/claude-sessions/${session_id}"
  mkdir -p "$session_dir"

  # Seed session with persisted auth (Claude OAuth, plugin tokens, etc.)
  cp -a "$CC_AUTH_DIR/claude-home/." "$session_dir/claude-home/"
  cp "$CC_AUTH_DIR/claude.json" "$session_dir/claude.json" 2>/dev/null || true

  command docker run --rm -it \
    --name "$session_id" \
    --add-host=host.docker.internal:host-gateway \
    \
    -v "$session_dir/claude-home:/home/node/.claude" \
    -v "$session_dir/claude.json:/home/node/.claude.json" \
    -v "$HOME/.config/gh:/home/node/.config/gh:ro" \
    -v "$PWD:/app:rw" \
    ${CONTEXT7_API_KEY:+-e "CONTEXT7_API_KEY=$CONTEXT7_API_KEY"} \
    \
    -w /app \
    claude-code "$@"

  local code=$?

  # Sync back
  cp "$session_dir/claude.json" "$CC_AUTH_DIR/claude.json" 2>/dev/null || true
  for f in credentials.json .credentials; do
    [[ -f "$session_dir/claude-home/$f" ]] && \
      cp "$session_dir/claude-home/$f" "$CC_AUTH_DIR/claude-home/" 2>/dev/null
  done

  # Clean up session scratch
  rm -rf "$session_dir" 2>/dev/null

  echo
  echo "Session $session_id exited with status $code"
  return $code
}

alias cc='claude_code_docker'

# Open a new wezterm tab with its own Claude session
cc_tab() {
  wezterm cli spawn -- zsh -ic "cd ${(q)PWD} && claude_code_docker $*"
}
