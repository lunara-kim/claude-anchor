# ADR 0006: Distribute and describe claude-anchor as a Hooks-category project

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

claude-anchor ships two artifacts — slash commands (`/anchor`, `/anchor-graduate`) and a `Stop` hook — which makes it eligible for listing in multiple categories of the `awesome-claude-code` curated directory. At the time of this decision, the `awesome-claude-code` README shows roughly 11 entries under Hooks and 47 entries under Slash-Commands (subdivided into seven sub-categories including "Context Loading & Priming" and "Documentation & Changelogs"). The directory's submission form allows only a single primary category. The choice affects both where the project is discoverable and how the project describes itself in its own README and elevator pitch.

## Decision

Submit and self-describe claude-anchor as a **Hooks** project. The slash commands are acknowledged as supporting surfaces, but the framing — in the README, in submission text, and in how the tool positions itself — leads with the Stop-hook mechanism that auto-triggers anchoring without user discipline.

## Rationale

The novel, hard-won contribution of claude-anchor is the Stop-hook mechanism — specifically the `decision:block` + `stop_hook_active` pattern that makes session-end automation actually reach Claude (see ADR 0002). The slash commands themselves are structured prompts that any user could write; the auto-trigger is the piece that distinguishes this project. In the Hooks category, no existing entry addresses context anchoring, so claude-anchor has a distinct position. In the Slash-Commands category, "Context Loading & Priming" and "Documentation & Changelogs" already contain several context-capture commands, and claude-anchor would blend in with them despite its different runtime model. Leading with the hook also writes a sharper one-line description.

## Rejected Alternatives

- **Submit under Slash-Commands → Context Loading & Priming.** More direct competition, weaker differentiation, and a framing that downplays the mechanism that makes the tool work without user discipline.
- **Submit twice, once per category.** The submission form is single-category; splitting would also split review attention.

## Consequences

- Discoverability tilts toward users browsing Hooks, not Slash-Commands. Slash-command readers may miss the project; the README's front matter mitigates this by describing both artifacts.
- The project's public identity is "a hook, plus helper commands". All README copy, release notes, and marketing follow that framing.
- If the directory later splits Hooks into sub-categories, claude-anchor is in a good position because its role ("structured persistence of design decisions") is distinct from existing Hooks entries.
