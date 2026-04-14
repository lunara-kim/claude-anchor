---
description: Graduate key decisions from FEATURE_CONTEXT.md into formal ADRs in docs/adr/
allowed-tools: Read, Write, Bash(date:*), Bash(ls:*), Bash(mkdir:*), Bash(find:*)
---

# /anchor-graduate — Feature Context → ADR promotion

When a feature is complete, promote the key decisions from `FEATURE_CONTEXT.md` into formal Architecture Decision Records under `docs/adr/`.

As the original article puts it: "significant decisions graduate to formal ADRs. For teams not yet using ADRs, this is a natural entry point."

## Execution guide

1. **Read FEATURE_CONTEXT.md**
   Read `FEATURE_CONTEXT.md` from the current directory. If missing, let the user know.

2. **Check existing ADR numbers**
   If `docs/adr/` exists, list the existing files to determine the next number.
   If not, create `docs/adr/` and start from 0001.

3. **Select decisions to graduate**
   From the Decisions table, pick decisions worth preserving as ADRs by these criteria:
   - Affects architecture or significant technology choices
   - Likely to be revisited in the future
   - Has rejected alternatives whose rationale matters

   Do not graduate pure implementation details (variable names, file layout, etc.).

4. **Create one ADR file per selected decision**
   For each selected decision, create a file in this format:

   Filename: `docs/adr/NNNN-[kebab-case-summary].md`

   ```markdown
   # ADR NNNN: [Decision title]

   Date: [date]
   Status: Accepted
   Feature: [feature name from FEATURE_CONTEXT.md]

   ## Context

   [Background and situation that required this decision. Use the Constraints section and context from FEATURE_CONTEXT.md.]

   ## Decision

   [What was decided. Be concrete.]

   ## Rationale

   [Why this decision was made. Expand on the "Rationale" column in FEATURE_CONTEXT.md.]

   ## Rejected Alternatives

   [Alternatives considered and the reasons they were rejected. Expand on the "Rejected alternatives" column.]

   ## Consequences

   [Resulting consequences of this decision — both positive and negative.]
   ```

5. **Mark FEATURE_CONTEXT.md as complete**
   After generating ADRs, add a completion marker to the top of `FEATURE_CONTEXT.md`:

   ```markdown
   > ✅ Completed — [date]
   > Key decisions graduated to docs/adr/NNNN-*.md
   ```

6. **Report results**
   Report the list and paths of the generated ADR files to the user.
   Note that `FEATURE_CONTEXT.md` can now be deleted or archived.

## Notes

Not every decision deserves an ADR. The feature document is a diary; ADRs are lessons.
Only graduate decisions whose *rationale* will still be valuable in the future.
