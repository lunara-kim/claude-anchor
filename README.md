# Context Anchoring Slash Commands for Claude Code

An implementation of Martin Fowler's [Context Anchoring](https://martinfowler.com/articles/reduce-friction-ai/context-anchoring.html) pattern as Claude Code slash commands, with automatic anchoring via a `Stop` hook.

> Korean version: [README.ko.md](README.ko.md)

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lunara-kim/claude-anchor/main/install.sh | bash
```

What the script does:
- Copies two anchor commands (`anchor.md`, `anchor-graduate.md`) to `~/.claude/commands/`.
- Installs `~/.claude/anchor-hook.py` (the Stop hook logic).
- Merges the Stop hook into `~/.claude/settings.json` (preserves existing settings, creates a timestamped backup).
- Replaces any previously installed claude-anchor hook cleanly (no duplicates).
- Removes the legacy `anchor-init.md` if present (its behavior is merged into `/anchor`).

> `jq` is only required when you already have a `~/.claude/settings.json`. If `jq` is missing, the script falls back to `python3`/`python`.

### Manual install

```bash
git clone https://github.com/lunara-kim/claude-anchor
cd claude-anchor
./install.sh
```

Or fully manual:
```bash
mkdir -p ~/.claude/commands
cp anchor.md anchor-graduate.md ~/.claude/commands/
# Merge settings.json manually with your existing one.
```

### Per-project install (team-shared)

```bash
mkdir -p .claude/commands
cp anchor.md anchor-graduate.md .claude/commands/
cp settings.json .claude/settings.json
```

## Update

Depending on how you installed:

**One-liner** — just re-run the same command:
```bash
curl -fsSL https://raw.githubusercontent.com/lunara-kim/claude-anchor/main/install.sh | bash
```
The installer identifies the existing hook by marker and replaces it, so nothing gets duplicated. `settings.json` is backed up with a timestamp on every run.

**git clone**:
```bash
cd claude-anchor && git pull && ./install.sh
```

**Symlink (advanced)** — clone once, symlink, and `git pull` to update:
```bash
git clone https://github.com/lunara-kim/claude-anchor ~/src/claude-anchor
ln -sf ~/src/claude-anchor/anchor.md          ~/.claude/commands/
ln -sf ~/src/claude-anchor/anchor-graduate.md ~/.claude/commands/
cd ~/src/claude-anchor && git pull
```

## Automatic anchoring (default)

So that context is not lost when you forget to run the command, `settings.json` ships with a **Stop hook**. Per the Claude Code spec, the hook returns a `{"decision":"block","reason":"..."}` JSON response so that **Claude actually reads the reason and acts on it** — a plain stdout echo is not propagated to Claude.

Flow:

1. When Claude tries to end its turn, `anchor-hook.py` runs.
2. It checks whether the current working directory contains `FEATURE_CONTEXT.md`.
3. **If it exists** → "If this session had substantive work, update it with `/anchor`."
4. **If it does not** → "If this session had substantive work, create one with `/anchor` (self-bootstrap)."
5. Claude inspects the session and decides whether to run `/anchor`.
6. On the next stop attempt, `stop_hook_active=true` is set, so the hook exits silently (no infinite loop).

"Substantive work" is interpreted broadly — feature implementation, test infrastructure, logging strategy, deployment pipelines, architectural refactors, tooling setup, anything that **involves design choices**. For quick questions or trivial fixes, Claude will judge it "not substantive" and end the turn without anchoring.

The result: **anchoring is managed automatically from feature kickoff through completion.** You can always run `/anchor` and `/anchor-graduate` manually as well.

To disable the automation, remove the `Stop` hook section from `~/.claude/settings.json` or delete `anchor-hook.py`.

## What this touches (transparency)

claude-anchor is local-only and makes no runtime network calls. Here is exactly what gets written and fetched.

**Files created or modified by `install.sh`:**
- `~/.claude/commands/anchor.md` — written
- `~/.claude/commands/anchor-graduate.md` — written
- `~/.claude/anchor-hook.py` — written
- `~/.claude/commands/anchor-init.md` — **deleted** if present (legacy cleanup)
- `~/.claude/settings.json` — merged (adds one `Stop` hook entry); a timestamped backup `settings.json.bak.YYYYMMDDHHMMSS` is created on every run

**Files created by the commands themselves (in your project directory):**
- `./FEATURE_CONTEXT.md` — created or updated by `/anchor`
- `./docs/adr/NNNN-*.md` — created by `/anchor-graduate`

**Network requests:**
- `install.sh`, when run via the curl one-liner, downloads `anchor.md`, `anchor-graduate.md`, `anchor-hook.py`, and `settings.json` from `raw.githubusercontent.com/lunara-kim/claude-anchor/main/`.
- After installation, nothing in this project makes network calls. `anchor-hook.py` and the slash commands only read/write local files.

**No telemetry. No auto-update. No elevated permissions required.** The installer does not call `sudo` and does not require `--dangerously-skip-permissions`.

## Uninstall

```bash
# Remove the slash commands
rm -f ~/.claude/commands/anchor.md ~/.claude/commands/anchor-graduate.md

# Remove the hook script
rm -f ~/.claude/anchor-hook.py

# Remove the Stop hook from settings.json
#   Option 1: restore from the backup that install.sh created
#     ls ~/.claude/settings.json.bak.*       # pick the most recent
#     cp ~/.claude/settings.json.bak.<TS> ~/.claude/settings.json
#
#   Option 2: edit ~/.claude/settings.json by hand and delete the hook entry
#     whose command references "anchor-hook.py"
```

`FEATURE_CONTEXT.md` and `docs/adr/` files in your project are yours to keep or delete. Nothing else is left behind.

## Demo — a minimal end-to-end session

A reproducible trace. Try this in a scratch directory after installing.

```text
$ mkdir demo && cd demo
$ claude
> We're adding email notifications. Use SES, not SendGrid —
> we already have an SES account in this AWS org and legal
> has cleared it. Sketch the sender module.

[Claude writes src/notifier.py with an SES client]

> ok that looks good, let's stop here

[Stop hook fires — Claude sees the reminder and runs /anchor]

/anchor
→ FEATURE_CONTEXT.md created with:
    Decisions:
      | Use AWS SES for email sending | Existing SES account in AWS
        org; legal has cleared SES but not SendGrid | SendGrid
        (extra vendor, not cleared); raw SMTP (no deliverability) |
    State:
      [x] Sketch sender module (src/notifier.py)
      [ ] Wire templates
      [ ] Retry / DLQ strategy

# Close the session. Next day:
$ claude
> Here's the context: @FEATURE_CONTEXT.md
> Continue from where we left off.

[Claude reads the file, knows WHY SES was chosen, picks up at "Wire templates"]

# When the feature ships:
/anchor-graduate
→ docs/adr/0001-use-ses-for-email-sending.md  (Context, Decision,
    Rationale, Rejected Alternatives, Consequences)
→ FEATURE_CONTEXT.md marked ✅ Completed
```

The point: the *reason* "SES, not SendGrid, because legal cleared it" survives the session boundary. Without anchoring, it tends to decay into "we chose SES" within a few days.

## Full workflow

```
substantive work starts
    ↓
/anchor   (manual or auto-triggered)
    → creates FEATURE_CONTEXT.md if missing, otherwise updates it
    → records decisions / rationale / rejected alternatives / constraints / state
    ↓
(loop: at the next session, share FEATURE_CONTEXT.md with Claude → ~30s context recovery)
    ↓
feature complete
    ↓
/anchor-graduate
    → graduates key decisions into docs/adr/NNNN-*.md
    → marks FEATURE_CONTEXT.md complete; safe to delete afterwards
```

## Commands

| Command | When | Role |
|---------|------|------|
| `/anchor [feature-name?]` | During or at the end of a session (or auto) | Create or update `FEATURE_CONTEXT.md` |
| `/anchor-graduate` | When a feature is complete | Promote key decisions into `docs/adr/` ADRs |

> The old `/anchor-init` command has been merged into `/anchor`. `/anchor` creates the file if missing and updates it if present.

## Why this exists

AI sessions are volatile by default. The longer a conversation runs, the sooner the *reasons* behind early decisions fade. These commands persist "why we did it" and "what we rejected" alongside "what we did".

- `FEATURE_CONTEXT.md` — work diary. Lives as long as the feature is in flight.
- `docs/adr/` — lessons. Only decisions whose rationale still matters in the future.

**Litmus test**: if you can close this session and start a new one tomorrow without feeling anxious about lost context, anchoring worked.

## License

MIT — see [LICENSE](LICENSE).
