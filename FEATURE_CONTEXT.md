# Feature: claude-anchor — Context Anchoring slash-command tool
_Created: 2026-04-15 | Last updated: 2026-04-15 (r2)_

> This file is a Context Anchoring document.
> Share it with Claude when starting a new session.
> Run `/anchor` at the end of each session to update it.
> When the feature is complete, run `/anchor-graduate` to promote key decisions to ADRs.

## Decisions

| Decision | Rationale | Rejected alternatives |
|----------|-----------|-----------------------|
| Merge `/anchor-init` into `/anchor` (self-bootstrap) | A separate init command only added usage friction. If `/anchor` creates the file when missing and updates it when present, the user only has to remember one action: "run `/anchor` at the end of a session." Real meeting-scribe sessions proved the gap: auto-trigger failed because `/anchor-init` had not been run. | Keep `/anchor-init` as a separate command (over-separation). / Alias the two commands (does not fix the problem; two commands still exist). |
| Implement the Stop hook as a `{"decision":"block","reason":"..."}` JSON response instead of an `echo` to stdout | Per the Claude Code spec, Stop hook stdout goes only to debug logs and is not surfaced to Claude. `decision:block` with `reason` is the only official mechanism to inject feedback into Claude. | stdout echo (verified broken). / SessionEnd hook (runs after the session ends, useless here). / UserPromptSubmit hook (fires at session start; cannot automate session end). |
| Use Claude Code's `stop_hook_active` flag to prevent infinite loops | An officially guaranteed escape hatch, delivered in the hook's stdin JSON. Simpler and more trustworthy than managing a custom session marker file. | Session-ID-based marker file at `/tmp/marker-{session_id}` (complex, OS path issues, needs cleanup). / One-shot counter (additional state to manage). |
| Keep hook logic in a separate `anchor-hook.py` script | Inlining JSON parsing and branching in bash becomes an escaping nightmare. The `command` field in settings.json should be a single line invoking a script. | Giant bash inline (unreadable, unmaintainable). / Node.js script (requiring Node for claude-anchor users is too heavy). |
| Prefer `jq` and fall back to `python3`/`python` when merging settings.json during install | `jq` is not bundled with Windows Git Bash. Python is almost always available on Windows / macOS / Linux. Auto-installing packages is avoided due to sudo/trust issues. | Require `jq` (barrier for Windows users). / Auto-install `jq` (OS-specific, permission-heavy). / Manual-merge instructions only (worst UX). |
| Automatically remove `anchor-init.md` when upgrading from older versions | If left behind, `/anchor-init` remains visible to users and causes confusion about a removed command. Naming the vanished command makes the migration clean. | Leave it and warn in README (invites mistakes). / Ship a deprecation-stub file (dead code). |
| Define "substantive work" for the Stop hook **broadly** (testing / logging / deploy / tooling included) | In the meeting-scribe project, introducing a test suite was interpreted as "not feature work", so auto-init did not fire. Anything involving design choices should qualify. | Narrow definition ("only feature implementation") — already disproved in practice. / Include everything — fires on quick questions too, causing noise. |
| Submit to `awesome-claude-code` under the **Hooks** category, not Slash-Commands | The novelty of claude-anchor is the Stop hook mechanism (`decision:block` + `stop_hook_active`), which was the hard-earned part. Hooks section has ~11 entries with no context-anchoring peer; Slash-Commands has 47 entries across 7 subcategories including "Context Loading & Priming" and "Documentation & Changelogs" where claude-anchor would blend in. Hook-first framing also writes a sharper description. | Submit under Slash-Commands/Context Loading & Priming (more competition, weaker differentiation). / Submit to both (the issue form is single-category). |
| Do not bundle `/add-to-changelog` (berrydev-ai) or similar adjacent commands into claude-anchor | Scope is Context Anchoring — decisions/rationale persistence. Changelog management is a different concern with its own conventions (Keep a Changelog, SemVer) and would dilute the tool's identity and complicate category choice. | Fork berrydev-ai's MIT-licensed command into this repo (scope creep, learning overhead). / Build a thin `/anchor-graduate` → CHANGELOG integration (extra surface area for uncertain value). |

## Constraints

- Bounded by the Claude Code Stop hook spec — nothing other than `decision:block` can instruct Claude to take additional action.
- `jq` is not preinstalled in Windows Git Bash — Python fallback is mandatory.
- `anchor-hook.py` must stick to Python 3.6+ syntax (widely available).
- Hook path is fixed to `$HOME/.claude/anchor-hook.py` — supporting alternatives would complicate settings.json synchronization.
- Slash command files must live at `.claude/commands/*.md` per the Claude Code spec.
- `awesome-claude-code` enforces **"resources must be at least one week old"** — submission window opens 2026-04-21 at the earliest (repo created 2026-04-14).
- `awesome-claude-code` submissions must come from the **github.com web UI issue form**; `gh` CLI programmatic submission is an auto-close offense. `gh issue create --web` is acceptable because it only opens a browser.

## Open Questions

- [ ] Can graduation be automated? "Feature complete" is domain knowledge only humans have today, so it is manual. Could events like a commit message or PR merge drive it?
- [ ] Distribution pattern for project-local `settings.json` — improve the install flow for teams that commit `.claude/settings.json`.
- [ ] Tuning how often the hook speaks up — currently it fires once per session. Refine the prompt so Claude reliably skips when it is "just a quick question".
- [ ] Feature-name inference when `/anchor` auto-fires — Claude infers from conversation; if it is wrong, the filename and section headings feel off.
- [ ] Actual macOS / Linux testing — verified only on Windows Git Bash so far. Possible issues: `$HOME` expansion, path separators, `python` vs `python3` name resolution.
- [ ] English-first distribution — README / command docs translated to English; may need further copy passes before an `awesome-claude-code` PR.

## State

- [x] Write `/anchor` and `/anchor-graduate` commands; self-bootstrap logic
- [x] Re-implement the Stop hook based on `decision:block` JSON responses
- [x] Split into `anchor-hook.py` Python script
- [x] Prevent loops with `stop_hook_active`
- [x] `install.sh` (jq + Python fallback, legacy cleanup)
- [x] Verified install/run on Windows Git Bash
- [x] README rewritten end-to-end (install / update / workflow)
- [x] Translate command docs and README to English (Korean kept in `README.ko.md`)
- [ ] Actual macOS / Linux testing
- [ ] Submit to awesome-claude-code via Issue Form (Hooks category) — gated by the "1 week old" rule; earliest window 2026-04-21
- [ ] During the wait: macOS/Linux install verification, short demo snippet in README, CONTRIBUTING Tips & Tricks compliance pass
- [ ] Long-term observation of auto-trigger behavior in real projects (e.g., meeting-scribe)

## Session Log

### 2026-04-14
- Initial idea: read Martin Fowler's Context Anchoring article; implement as Claude Code slash commands.
- Wrote `/anchor-init`, `/anchor`, `/anchor-graduate` as three commands.
- Created `lunara-kim/claude-anchor` on GitHub; initial push.
- Added the Stop hook (initial echo-based version).
- Wrote `install.sh` with a Python fallback (for environments without `jq`).
- Real-world use in meeting-scribe: discovered that auto-init did not fire when a test suite was introduced.

### 2026-04-15
- Observed the auto-trigger fail again during a structured-logging session.
- Root cause investigation: the Claude Code docs confirm that Stop hook stdout is not propagated to Claude.
- Switched the mechanism to a `decision:block` + `reason` JSON response — Claude now actually reads the reason and acts.
- Added `stop_hook_active` flag handling to prevent infinite loops.
- Split the hook into a standalone `anchor-hook.py` (avoid inline bash JSON manipulation).
- Merged `/anchor-init` into `/anchor` (self-bootstrap) — removes usage friction.
- Broadened the Stop hook's definition of "substantive work" (testing / logging / deploy / tooling included).
- Verified live hook firing (`Stop hook feedback` observed in this session).
- Wrote this `FEATURE_CONTEXT.md` for the tool itself (meta-anchoring).
- Translated command docs and README to English for community distribution; preserved the Korean README as `README.ko.md`. Target: submit to `awesome-claude-code`.
- Committed and pushed English docs (`0f75f1c`); tagged `v0.1.0`; added 8 GitHub topics (`claude-code`, `claude-code-hooks`, `claude-code-commands`, `slash-commands`, `context-anchoring`, `adr`, `anthropic`, `ai-tooling`).
- Installed `gh` CLI via `winget` and authenticated as `lunara-kim`.
- Researched `awesome-claude-code` submission process — **Issue Form only; PR/gh-CLI submissions are forbidden and risk ban**.
- Investigated `/add-to-changelog` (berrydev-ai, MIT) — decided **not** to bundle; keep claude-anchor scope tight to Context Anchoring.
- Decided to submit under the **Hooks** category rather than Slash-Commands. Reasons: fewer peers (11 vs 47), the Stop-hook mechanism is the novel contribution, no existing context-anchoring entry in Hooks.
- Read the `recommend-resource.yml` issue template — discovered two gating rules: (1) resources must be at least **one week old** (blocks submission until 2026-04-21), (2) `gh` CLI programmatic submission is forbidden (auto-close), only web UI or `gh issue create --web` allowed. Deferred submission; lined up pre-submission work (macOS/Linux test, demo snippet, CONTRIBUTING Tips compliance).
