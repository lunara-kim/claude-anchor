# ADR 0003: Hook logic lives in a separate Python script, not inlined in settings.json

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

The Stop hook needs to read JSON from stdin (`stop_hook_active` and `cwd`), check whether `FEATURE_CONTEXT.md` exists in the project directory, and write a JSON response to stdout (see ADR 0002). Claude Code's `settings.json` lets a hook be specified as a shell command string, so this logic could theoretically be inlined as a single bash command. In practice, JSON parsing, file-existence checks, conditional branching, and JSON emission produce multi-level escaping once they all have to fit inside a double-quoted JSON string inside a settings file, and debugging that form is painful.

## Decision

Keep hook behavior in a standalone script, `~/.claude/anchor-hook.py`. The `command` field in `settings.json` is a one-liner that invokes this script with a `python3` preference and a `python` fallback.

## Rationale

A separate file lets the logic be written in a readable language, tested independently, and edited without touching JSON. Python was chosen as the implementation language because it is already installed in practice on Windows, macOS, and Linux environments where Claude Code runs, and its standard library covers JSON and filesystem checks without dependencies. Python 3.6+ syntax is sufficient, so no modern-runtime constraints are imposed on users.

## Rejected Alternatives

- **Inline bash command in `settings.json`.** The required escaping for JSON parsing and emission is error-prone and unreadable; maintenance would be the first thing to break as the hook evolves.
- **Node.js script.** Node is not universally present on developer machines, particularly for users who only do Python or other-language work. Requiring Node as a precondition for a single-file tool is too heavy a dependency.

## Consequences

- Hook behavior can be unit-tested and version-controlled as real code.
- The installer must place an additional file (`anchor-hook.py`) in a fixed location; that path is canonicalized at `$HOME/.claude/anchor-hook.py` to keep `settings.json` stable across machines.
- Users need `python3` (or `python`) on `PATH`. This is a very mild constraint compared to requiring `jq`, which drives the separate install-merge decision in ADR 0004.
