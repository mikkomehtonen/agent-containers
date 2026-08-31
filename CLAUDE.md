# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- `make all` - Build all containers
- `make claude-code` - Build Claude Code container
- `make openai-codex` - Build OpenAI Codex container
- `make open-code` - Build OpenCode container
- `make clean` - Remove container images
- `make deep-clean` - Remove container images and prune the build cache

## Run Commands
- Claude Code: `docker run -it --rm -v ${HOME}/.config/claude/claude.json:/home/node/.claude.json:rw -v $(pwd):/app:rw claude-code`
- OpenAI Codex: `docker run -it --rm -e OPENAI_API_KEY -v ${HOME}/.config/codex:/home/node/.codex:rw -v $(pwd):/app:rw openai-codex`
- OpenCode: `docker run -it --rm --add-host=host.docker.internal:host-gateway -v ${HOME}/.local/state/opencode:/home/node/.local/state/opencode -v ${HOME}/.local/share/opencode:/home/node/.local/share/opencode -v ${HOME}/.config/opencode:/home/node/.config/opencode -v $(pwd):/app:rw open-code`
- Aider: `docker run -it --rm --user $(id -u):$(id -g) -e OPENAI_API_KEY -e ANTHROPIC_API_KEY -v $(pwd):/app:rw paulgauthier/aider`
- Browser smoke test (inside any running container): `bash base/browser-smoke-test.sh`

## Code Style Guidelines
- Docker-based project with separate containers for different AI assistants
- Use explicit mounting of configuration files with appropriate permissions (700/600)
- Keep API keys and credentials in mounted configuration files, never in code
- Document configuration persistence in README files per tool
- Bash commands should use `$(pwd)` for current directory mounting
- Prioritize security for configuration files containing API keys