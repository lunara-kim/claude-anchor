---
description: Create or update the feature context document with session decisions
allowed-tools: Read, Write, Bash(date:*), Bash(ls:*), Bash(cat:*)
---

# /anchor — Context Anchoring

Persist the decisions made during this session to a local feature document (`FEATURE_CONTEXT.md`).
Creates the file if it does not exist, updates it if it does.

## How it works

1. **Check current directory**: look for `FEATURE_CONTEXT.md`.

2. **If missing → create (self-bootstrap)**:
   - If `$ARGUMENTS` contains a feature name, use it.
   - Otherwise infer the feature name from the current conversation (e.g., "introduce test suite", "email notification feature").
   - If ambiguous, briefly ask the user.
   - Create a new file using the "Document format" below, then immediately fill in this session's decisions / constraints / state.

3. **If present → update**:
   - Read the existing file to understand current state.
   - Add or refresh decisions / constraints / questions / progress from this session.

## Document format

```markdown
# Feature: [name]
_Created: [date] | Last updated: [date]_

> This file is a Context Anchoring document.
> Share it with Claude when starting a new session.
> Run `/anchor` at the end of each session to update it.
> When the feature is complete, run `/anchor-graduate` to promote key decisions to ADRs.

## Decisions
| Decision | Rationale | Rejected alternatives |
|----------|-----------|-----------------------|
| ... | ... | ... |

## Constraints
- ...

## Open Questions
- [ ] Unresolved question
- [x] Resolved question (resolution: ...)

## State
- [x] Completed work
- [ ] Work for the next session

## Session Log
### [date]
- Summary of the main work done in this session
```

## Execution guide

1. Enter create or update mode based on whether `FEATURE_CONTEXT.md` exists.
2. Add newly made decisions from this conversation to the Decisions table.
3. Add any new constraints to Constraints.
4. Update Open Questions to the latest state (resolved → [x], new → [ ]).
5. Update the State checklist to reflect current progress.
6. Append today's date and this session's summary to Session Log.
7. Save the file and briefly report what was written.

**Important**:
- Always record the *rationale* and *rejected alternatives* for each decision. "Why" matters more than "what".
- Interpret "substantive work" broadly — not only feature additions, but also test infrastructure, logging strategy, deployment pipelines, architectural refactors, and any work that **involves design choices**. Trivial bug fixes or formatting do not count.
