#!/usr/bin/env bash
set -euo pipefail

# claude-anchor installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lunara-kim/claude-anchor/main/install.sh | bash
#   or: ./install.sh  (from cloned repo)

REPO_URL="https://github.com/lunara-kim/claude-anchor.git"
RAW_URL="https://raw.githubusercontent.com/lunara-kim/claude-anchor/main"
CLAUDE_DIR="${HOME}/.claude"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
COMMANDS=(anchor.md anchor-init.md anchor-graduate.md)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
err()   { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

mkdir -p "${COMMANDS_DIR}"

# Determine source: local repo if install.sh is run from clone, else fetch from raw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [[ -n "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/anchor.md" ]]; then
  SOURCE="local"
  info "Installing from local repo: ${SCRIPT_DIR}"
else
  SOURCE="remote"
  info "Installing from remote: ${REPO_URL}"
fi

# 1) Install command files
for cmd in "${COMMANDS[@]}"; do
  dest="${COMMANDS_DIR}/${cmd}"
  if [[ "${SOURCE}" == "local" ]]; then
    cp "${SCRIPT_DIR}/${cmd}" "${dest}"
  else
    curl -fsSL "${RAW_URL}/${cmd}" -o "${dest}"
  fi
  info "Installed ${dest}"
done

# 2) Merge settings.json
# The Stop hook we want to install:
HOOK_CMD='if [ -f FEATURE_CONTEXT.md ]; then echo '"'"'A FEATURE_CONTEXT.md exists in this project. If meaningful decisions, rejected alternatives, new constraints, or progress were made in this session, run /anchor now to update it before the session ends. Skip if no substantive changes.'"'"'; else echo '"'"'No FEATURE_CONTEXT.md in this project. If this session involved substantive feature work (design decisions, implementation choices, rejected alternatives, multi-step scope), run /anchor-init [feature-name] to create one and capture the context. Skip for quick questions, exploration, or one-off fixes.'"'"'; fi'

# Fast path: no existing settings.json → write directly, no jq needed.
if [[ ! -f "${SETTINGS_FILE}" ]]; then
  if [[ "${SOURCE}" == "local" ]]; then
    cp "${SCRIPT_DIR}/settings.json" "${SETTINGS_FILE}"
  else
    curl -fsSL "${RAW_URL}/settings.json" -o "${SETTINGS_FILE}"
  fi
  info "Created ${SETTINGS_FILE} with Stop hook"
  info "Done. Restart Claude Code to pick up the new commands and hook."
  exit 0
fi

# Existing settings.json → need jq to merge safely.
if ! command -v jq >/dev/null 2>&1; then
  warn "jq not found; cannot safely merge into existing ${SETTINGS_FILE}."
  warn "Install jq and re-run:"
  warn "  Windows:  winget install jqlang.jq    (or: scoop install jq)"
  warn "  macOS:    brew install jq"
  warn "  Linux:    apt install jq  /  dnf install jq"
  warn "Or merge manually from: ${RAW_URL}/settings.json"
  exit 0
fi

backup="${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
cp "${SETTINGS_FILE}" "${backup}"
info "Backed up existing settings to ${backup}"

# Remove any existing claude-anchor hook (identified by the FEATURE_CONTEXT.md marker)
# then append our hook. Idempotent: re-running install replaces the hook cleanly.
tmp=$(mktemp)
jq --arg cmd "${HOOK_CMD}" '
  .hooks //= {}
  | .hooks.Stop //= []
  | .hooks.Stop |= (
      map(
        if (.hooks? // []) | any(.command? // "" | test("FEATURE_CONTEXT\\.md"))
        then
          .hooks |= map(select((.command? // "") | test("FEATURE_CONTEXT\\.md") | not))
        else . end
      )
      | map(select((.hooks? // []) | length > 0))
    )
  | .hooks.Stop += [{
      "matcher": "",
      "hooks": [{"type": "command", "command": $cmd}]
    }]
' "${SETTINGS_FILE}" > "${tmp}" && mv "${tmp}" "${SETTINGS_FILE}"

info "Merged Stop hook into ${SETTINGS_FILE}"
info "Done. Restart Claude Code to pick up the new commands and hook."
