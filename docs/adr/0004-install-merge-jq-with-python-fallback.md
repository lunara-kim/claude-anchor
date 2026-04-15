# ADR 0004: `install.sh` merges `settings.json` with `jq` preferred and `python` as fallback

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

Installing claude-anchor requires merging a `Stop` hook entry into the user's `~/.claude/settings.json` without destroying whatever other hooks or settings are already there. JSON merge is not safely expressible in plain shell, so a JSON-aware tool is needed. `jq` is the canonical choice on Unix-likes, but it is not installed by default on Windows Git Bash — which is a first-class target environment for this project — and asking users to install a package just to run the installer is a meaningful adoption barrier. Auto-installing `jq` is also undesirable because it would require `sudo` or package-manager-specific logic, which breaks the "run one curl command, done" promise.

## Decision

The installer tries `jq` first; if `jq` is not on `PATH`, it falls back to `python3`, then `python`. The same idempotent merge algorithm is implemented in both: strip any previously installed claude-anchor hook (identified by a command marker referencing `FEATURE_CONTEXT.md` or `anchor-hook.py`), then append the current Stop hook. The user's existing `settings.json` is backed up with a timestamp before modification. If neither `jq` nor Python is available, the installer explains the options and exits without touching the file.

## Rationale

Python is already required by the hook itself (ADR 0003), so "if Python exists, you can install" imposes no new dependency. `jq` is still preferred when available because the merge expression is shorter and the tool is purpose-built for this. The idempotent strip-then-append pattern makes re-running the installer a safe operation, which matters for the one-liner update path.

## Rejected Alternatives

- **Require `jq`.** Blocks Windows users by default; measurable adoption friction.
- **Auto-install `jq` for the user.** Requires OS detection, elevated permissions, and trust in whatever package manager is invoked. A net loss for an installer that otherwise does nothing privileged.
- **Manual-merge-only instructions.** Forces every user through a multi-step JSON edit; worst possible UX for a tool that wants to feel like a one-line install.

## Consequences

- The one-liner install works on a default Windows Git Bash install (Python ships with Windows or is trivially available) as well as macOS and Linux.
- There are two code paths to keep in sync: `jq` expression and the equivalent Python block. Semantic drift between them is a maintenance risk; both live in the same `install.sh` for close review.
- Every install run writes a new timestamped backup. Users who run the installer many times will accumulate `settings.json.bak.*` files; this is intentional, and the README documents uninstall steps that include restoring from a chosen backup.
