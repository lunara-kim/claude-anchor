# ADR 0001: Self-bootstrapping `/anchor` command

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

The tool originally shipped two separate commands: `/anchor-init` to create `FEATURE_CONTEXT.md` on first use, and `/anchor` to update it afterwards. In a real-world pilot on the meeting-scribe project, a session that involved substantive work (introducing a test suite) ended without anchoring because `/anchor-init` had never been run and there was nothing for the auto-trigger to update. The two-command design had made the user responsible for knowing which command to run and when — a requirement that failed in practice.

## Decision

Merge `/anchor-init` into `/anchor` and make `/anchor` self-bootstrapping: if `FEATURE_CONTEXT.md` does not exist, `/anchor` creates it (inferring the feature name from `$ARGUMENTS` or the conversation context); if it does exist, `/anchor` updates it. Users have exactly one command to remember.

## Rationale

The cost of a separate init command is paid every time a feature begins — precisely the moment the user is focused on the work, not the tooling. The pilot failure showed that "remember to run init first" is not a policy a user can be relied on to follow, especially when the auto-trigger hook assumes the file already exists. A single command that handles both states removes the failure mode entirely.

## Rejected Alternatives

- **Keep `/anchor-init` as a separate command.** Preserves a clean conceptual split ("init" vs "update") but keeps the failure mode that motivated this decision.
- **Alias the two commands to each other.** Both names keep existing, so the cognitive load of "which one do I run?" does not go away; the alias only hides the issue instead of removing it.

## Consequences

- Users have a simpler mental model and the auto-trigger path works end-to-end from a cold project.
- The `/anchor` prompt becomes slightly more complex because it branches on file existence, but the branching is deterministic and testable.
- Old installations may still have `anchor-init.md` in `~/.claude/commands/`; the installer removes it on upgrade so the vanished command does not linger in the UI.
