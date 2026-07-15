---
name: setup-matt-pocock-skills
description: Configure this repo for the engineering skills — set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills.
disable-model-invocation: true
---

# Setup Matt Pocock's Skills

Scaffold the per-repo configuration that the engineering skills assume:

- **Issue tracker** — where issues live (GitHub by default; local markdown is also supported out of the box)
- **Triage labels** — the strings used for the five canonical triage roles
- **Domain docs** — where the domain glossary and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

> Repo note (this project): the domain glossary is `KONTEXT.md` (German), NOT `CONTEXT.md`.
> Do not create a `CONTEXT.md` — `docs/agents/domain.md` points readers at `KONTEXT.md`.
> The issue tracker is local markdown under `.scratch/`. The `triage` skill is NOT installed,
> so Section B / `docs/agents/triage-labels.md` are skipped.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config` — is this a GitHub repo? Which one?
- `AGENTS.md` and `CLAUDE.md` at the repo root — does either exist? Is there already an `## Agent skills` section in either?
- `KONTEXT.md` at the repo root — this project's domain glossary (German).
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/` — does this skill's prior output already exist?
- `.scratch/` — sign that a local-markdown issue tracker convention is already in use
- Is the `triage` skill installed? This decides whether Section B runs at all.
- Monorepo signals — a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*`. Their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order — one section, one answer, then the next. Lead each section with the recommended answer.

**Section A — Issue tracker.** Where issues live for this repo. Options: GitHub (`gh`), GitLab (`glab`), Local markdown (`.scratch/<feature>/`), or Other (freeform prose). Record the choice in `docs/agents/issue-tracker.md`.

**Section B — Triage label vocabulary.** Skip entirely if the `triage` skill isn't installed. If installed, keep the five default labels unless the user overrides.

**Section C — Domain docs.** Default to single-context — one domain glossary + `docs/adr/` at the repo root. In this repo the glossary is `KONTEXT.md`.

### 3. Confirm and edit

Show the user a draft of the `## Agent skills` block for `CLAUDE.md` / `AGENTS.md` and the contents of `docs/agents/issue-tracker.md` and `docs/agents/domain.md` before writing.

### 4. Write

Pick the file to edit: `CLAUDE.md` if it exists, else `AGENTS.md`, else ask. Add or update in-place an `## Agent skills` block:

```markdown
## Agent skills

### Issue tracker

[one-line summary]. See `docs/agents/issue-tracker.md`.

### Domain docs

[one-line summary]. See `docs/agents/domain.md`.
```

Then write the docs files from the seed templates in this skill folder:

- [issue-tracker-github.md](./issue-tracker-github.md)
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md)
- [issue-tracker-local.md](./issue-tracker-local.md)
- [triage-labels.md](./triage-labels.md) — only if `triage` is installed
- [domain.md](./domain.md)

### 5. Done

Tell the user setup is complete and that they can edit `docs/agents/*.md` directly later.
