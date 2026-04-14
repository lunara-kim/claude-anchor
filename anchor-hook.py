#!/usr/bin/env python3
"""claude-anchor Stop hook.

Reads the Stop hook payload from stdin and, when appropriate, returns a
`decision: block` response that instructs Claude to run /anchor before
ending the session.

Loop safety: Claude Code sets `stop_hook_active: true` when a Stop event
fires as a direct result of a previously-blocked stop. When that flag is
set, we exit without blocking so Claude can always escape.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


REASON_HAS_CONTEXT = (
    "A FEATURE_CONTEXT.md exists in this project. "
    "If this session included substantive work (new decisions, rejected "
    "alternatives, new constraints, or progress on existing tasks), run "
    "/anchor now to update it before the session ends. "
    "If nothing substantive happened (quick question, pure exploration, "
    "trivial fix), acknowledge that and end the turn without running /anchor."
)

REASON_NO_CONTEXT = (
    "No FEATURE_CONTEXT.md yet. If this session involved substantive work "
    "with design choices — feature implementation, testing infrastructure, "
    "logging strategy, deployment pipeline, architectural refactors, tooling "
    "setup, any multi-step scope — run /anchor now to create one and capture "
    "the context. If nothing substantive happened, acknowledge that and end "
    "the turn without running /anchor."
)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Malformed or empty stdin: allow stop silently.
        return

    # Already blocked once this session → do not block again.
    if payload.get("stop_hook_active"):
        return

    cwd = Path(payload.get("cwd") or os.getcwd())
    has_context = (cwd / "FEATURE_CONTEXT.md").is_file()
    reason = REASON_HAS_CONTEXT if has_context else REASON_NO_CONTEXT

    json.dump({"decision": "block", "reason": reason}, sys.stdout)


if __name__ == "__main__":
    main()
