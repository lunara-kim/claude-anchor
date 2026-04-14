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
HOOK_SCRIPT="${CLAUDE_DIR}/anchor-hook.py"
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

# 2) Install hook script
if [[ "${SOURCE}" == "local" ]]; then
  cp "${SCRIPT_DIR}/anchor-hook.py" "${HOOK_SCRIPT}"
else
  curl -fsSL "${RAW_URL}/anchor-hook.py" -o "${HOOK_SCRIPT}"
fi
chmod +x "${HOOK_SCRIPT}" 2>/dev/null || true
info "Installed ${HOOK_SCRIPT}"

# 3) Merge settings.json
# The Stop hook command that invokes our hook script.
HOOK_CMD='python3 "$HOME/.claude/anchor-hook.py" 2>/dev/null || python "$HOME/.claude/anchor-hook.py"'

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
  # Marker matches either legacy inline hook (FEATURE_CONTEXT.md) or
  # current script-based hook (anchor-hook.py).
  jq --arg cmd "${HOOK_CMD}" '
    .hooks //= {}
    | .hooks.Stop //= []
    | .hooks.Stop |= (
        map(
          if (.hooks? // []) | any(.command? // "" | test("FEATURE_CONTEXT\\.md|anchor-hook\\.py"))
          then
            .hooks |= map(select((.command? // "") | test("FEATURE_CONTEXT\\.md|anchor-hook\\.py") | not))
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

# Strip previous claude-anchor hooks (legacy FEATURE_CONTEXT.md marker
# or current anchor-hook.py marker).
cleaned = []
for entry in stop_entries:
    inner = entry.get("hooks", []) or []
    def _is_ours(cmd: str) -> bool:
        return "FEATURE_CONTEXT.md" in cmd or "anchor-hook.py" in cmd
    kept = [h for h in inner if not _is_ours(h.get("command") or "")]
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
