# ADR 0005: Define "substantive work" broadly, including testing, logging, deploy, and tooling

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

The Stop hook reminder asks Claude to judge whether a session included "substantive work" before deciding to run `/anchor`. The definition of that term directly shapes when anchoring happens. In the meeting-scribe pilot, introducing a test suite was interpreted by Claude as "not feature work", and the auto-trigger did not fire — a false negative that left real design decisions (test framework choice, fixture strategy, coverage targets) unanchored. Conversely, defining "substantive" to include every session would cause the hook to interrupt quick questions and trivial fixes, producing noise that would erode trust in the tool.

## Decision

The hook's reminder text explicitly enumerates qualifying categories: feature implementation, test infrastructure, logging strategy, deployment pipelines, architectural refactors, tooling setup — anything that involves design choices. It also explicitly excludes quick questions, pure exploration, and trivial fixes. Claude is expected to apply this definition each turn and acknowledge when a session was not substantive rather than forcing an `/anchor` call.

## Rationale

The failure mode that shipped this project was under-triggering, not over-triggering, so the definition leans toward inclusion. The categories named in the prompt are exactly the work types that have historical ADRs and rejected alternatives in mature projects — the places where "why did we pick X?" will matter months later. By naming them explicitly in the prompt, we give Claude a concrete classifier rather than an abstract one. Leaving the final judgment to Claude (rather than hard-coding a regex over tool calls, for example) means the behavior degrades gracefully as the kinds of "substantive" work evolve.

## Rejected Alternatives

- **Narrow definition: "feature implementation only".** Directly disproved by the meeting-scribe incident where test-suite work was a real design choice but did not match "feature".
- **Fire on every session.** Turns the hook into noise; users will add `stop_hook_active: true` manually or remove the hook to escape. Loses the battle to keep anchoring cheap.
- **Programmatic classification (e.g., by tool-use pattern).** Brittle; does not generalize to future kinds of work; places product logic in the wrong layer.

## Consequences

- Anchoring fires on a broader set of sessions, including those that traditional issue trackers would not call "features". This matches the lived reality of how software projects accumulate decisions.
- Hook reliability depends on Claude's prompt-following quality. If Claude misjudges a session, the fallback is the manual `/anchor` command, which the user can always invoke.
- The "substantive work" enumeration is part of the project's public interface via the prompt text. Expanding or narrowing it later is a change users may notice in observed behavior.
