# ADR 0002: Stop hook returns `decision:block` JSON, with `stop_hook_active` as loop escape

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

The original Stop hook wrote a reminder message to stdout in the hope that Claude would read it and run `/anchor` before ending the turn. In testing this behavior never occurred: the auto-trigger simply did not fire. Investigation of the Claude Code hook specification confirmed that Stop hook stdout is routed only to debug logs and is not surfaced to Claude in the conversation. The sole official mechanism for a Stop hook to inject feedback that Claude will actually read is a JSON response of the form `{"decision":"block","reason":"..."}`, which blocks the end-of-turn and delivers `reason` to Claude as system feedback.

Returning `decision:block` introduces a secondary problem: if Claude then stops again without taking the requested action, the hook would block again and loop forever. Claude Code's spec provides a `stop_hook_active` flag in the hook's stdin payload that is set to `true` when the current stop event was triggered by a previously-blocked stop — an officially guaranteed escape hatch.

## Decision

Implement the Stop hook so that:
1. On the first stop event, it returns `{"decision":"block","reason":"<context-aware reminder>"}` — the reason text differs depending on whether `FEATURE_CONTEXT.md` exists.
2. If the incoming payload has `stop_hook_active: true`, the hook exits silently without blocking, letting the stop succeed.

## Rationale

`decision:block` is the only documented path for a Stop hook to reach Claude's context. Using stdout echoes was verified broken; no workaround using other hook types addresses the same moment in the lifecycle. The `stop_hook_active` flag is preferred over custom state files (e.g., session-ID-scoped markers in `/tmp`) because it is defined by the platform, already delivered in the stdin JSON, and needs no cleanup.

## Rejected Alternatives

- **Stdout echo from the Stop hook.** Empirically did not surface to Claude; contradicted by the hook spec.
- **`SessionEnd` hook.** Fires after the session is already over; nothing can be injected back into Claude's context at that point.
- **`UserPromptSubmit` hook.** Fires at session start, not end; cannot automate the "remember to anchor before you stop" behavior.
- **Session-ID-based marker files (`/tmp/marker-{session_id}`) for loop prevention.** Introduces OS-dependent path handling, cleanup duties, and more state than the platform-provided flag requires.
- **One-shot counter persisted between hook invocations.** Extra state to manage, and still worse than an officially guaranteed flag.

## Consequences

- Automatic anchoring finally works end-to-end: Claude receives the reason and can either run `/anchor` or acknowledge that the session was not substantive.
- The hook is strictly dependent on Claude Code spec semantics — any future change to how `decision:block` or `stop_hook_active` behaves is a compatibility risk for this project.
- Because the hook blocks once per session, Claude must be trusted to make a judgment on whether the session was "substantive". That judgment quality is addressed separately (see ADR 0005).
