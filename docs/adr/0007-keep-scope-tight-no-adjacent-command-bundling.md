# ADR 0007: Keep scope tight — do not bundle adjacent commands

Date: 2026-04-15
Status: Accepted
Feature: claude-anchor — Context Anchoring slash-command tool

## Context

Several other Claude Code slash commands in the community (for example `/add-to-changelog` by berrydev-ai, which is MIT-licensed) solve adjacent problems in the "persist structured context to a local markdown file" neighborhood. Bundling them into claude-anchor is technically straightforward — copy the files into `.claude/commands/`, update the installer's `COMMANDS` array, preserve their license and author credit — and would let users get a richer set of commands from a single install. This raises the question of whether claude-anchor should become a small collection rather than a focused tool.

## Decision

Keep claude-anchor's scope strictly focused on Context Anchoring — the persistence of design decisions, rationale, and rejected alternatives into `FEATURE_CONTEXT.md` and the graduation of selected decisions into `docs/adr/`. Do not bundle adjacent commands. Reference complementary tools via links in the README when relevant; do not copy them into the repo.

## Rationale

Each adjacent concern (changelog management, release notes, commit message drafting) has its own conventions, its own file formats, and its own upgrade cadence. Merging several such tools into one package dilutes the project's identity, complicates category choices for distribution (see ADR 0006), and forces the maintainer to track upstream changes across multiple unrelated codebases. Claude Code users can already install as many commands as they want; there is no actual benefit to packaging them together beyond the installer UX, which is a weak reason to absorb unbounded surface area. The project's value proposition ("the Stop hook that catches the moment before context is lost") compresses badly once unrelated commands are in the box.

## Rejected Alternatives

- **Fork `/add-to-changelog` into this repo.** MIT licensing would permit it, but the cost is scope creep and an ongoing obligation to mirror upstream changes or explain the divergence.
- **Build a thin `/anchor-graduate` → CHANGELOG.md integration.** Smaller surface than a full bundle, but still couples claude-anchor to a changelog format (Keep a Changelog, SemVer) whose evolution is outside this project's concern. The value delivered per added line of code is low.

## Consequences

- The README and category framing stay crisp. A user who installs claude-anchor knows what they got and what it does.
- Users who want a changelog command install it separately. This is a one-time cost per user, not a recurring cost on the maintainer.
- Future feature proposals ("can you add X?") have a principled default answer of "no, unless it is specifically about anchoring decisions". Scope creep is harder.
