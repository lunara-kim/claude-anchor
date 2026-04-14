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
COMMANDS=(anchor.md anchor-graduate.md)
# Legacy command files to remove if present (older versions installed them)
LEGACY_COMMANDS=(anchor-init.md)

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

# Clean up legacy files (anchor-init.md was merged into anchor.md)
for old in "${LEGACY_COMMANDS[@]}"; do
  if [[ -f "${COMMANDS_DIR}/${old}" ]]; then
    rm "${COMMANDS_DIR}/${old}"
    info "Removed legacy ${COMMANDS_DIR}/${old} (functionality merged into /anchor)"
  fi
done

# 2) Merge settings.json
# The Stop hook we want to install:
HOOK_CMD='if [ -f FEATURE_CONTEXT.md ]; then echo '"'"'A FEATURE_CONTEXT.md exists in this project. If this session included substantive work (new decisions, rejected alternatives, new constraints, or progress on existing tasks), run /anchor now to update it before the session ends.'"'"'; else echo '"'"'No FEATURE_CONTEXT.md yet. If this session involved substantive work with design choices — feature implementation, testing infrastructure, logging strategy, deployment pipeline, architectural refactors, tooling setup, any multi-step scope — run /anchor now to create one and capture the context. Skip only for quick questions, pure exploration, or trivial fixes.'"'"'; fi'

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

# Existing settings.json → merge safely. Try jq first, then python as fallback.
backup="${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
cp "${SETTINGS_FILE}" "${backup}"
info "Backed up existing settings to ${backup}"

if command -v jq >/dev/null 2>&1; then
  MERGER="jq"
elif command -v python3 >/dev/null 2>&1; then
  MERGER="python3"
elif command -v python >/dev/null 2>&1; then
  MERGER="python"
else
  warn "Neither jq nor python found; cannot safely merge into existing ${SETTINGS_FILE}."
  warn "Install one of them and re-run:"
  warn "  Windows:  winget install jqlang.jq   (or install Python from python.org)"
  warn "  macOS:    brew install jq            (or python3 is usually preinstalled)"
  warn "  Linux:    apt install jq             (or apt install python3)"
  warn "Or merge manually from: ${RAW_URL}/settings.json"
  exit 0
fi

tmp=$(mktemp)

if [[ "${MERGER}" == "jq" ]]; then
  # Remove any existing claude-anchor hook (identified by FEATURE_CONTEXT.md marker),
  # then append. Idempotent: re-running install replaces the hook cleanly.
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
  info "Merged Stop hook via jq into ${SETTINGS_FILE}"
else
  # Python fallback: same idempotent merge as the jq version above.
  HOOK_CMD="${HOOK_CMD}" SETTINGS_FILE="${SETTINGS_FILE}" OUT="${tmp}" "${MERGER}" - <<'PY'
import json, os, sys

settings_file = os.environ["SETTINGS_FILE"]
out           = os.environ["OUT"]
hook_cmd      = os.environ["HOOK_CMD"]

with open(settings_file, "r", encoding="utf-8") as f:
    data = json.load(f)

hooks = data.setdefault("hooks", {})
stop_entries = hooks.setdefault("Stop", [])

# Strip previous claude-anchor hooks (identified by FEATURE_CONTEXT.md marker).
cleaned = []
for entry in stop_entries:
    inner = entry.get("hooks", []) or []
    kept = [h for h in inner if "FEATURE_CONTEXT.md" not in (h.get("command") or "")]
    if kept:
        entry = dict(entry)
        entry["hooks"] = kept
        cleaned.append(entry)
    elif not inner:
        cleaned.append(entry)

cleaned.append({
    "matcher": "",
    "hooks": [{"type": "command", "command": hook_cmd}],
})
hooks["Stop"] = cleaned

with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
  mv "${tmp}" "${SETTINGS_FILE}"
  info "Merged Stop hook via ${MERGER} into ${SETTINGS_FILE}"
fi

info "Done. Restart Claude Code to pick up the new commands and hook."
