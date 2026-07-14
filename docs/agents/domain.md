# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring.

## Before exploring, read this

- **`KONTEXT.md`** at the repo root — this project's domain glossary and handoff doc (German).
  **This repo uses `KONTEXT.md`, not `CONTEXT.md`.** Do not create a `CONTEXT.md`; do not duplicate
  `KONTEXT.md`'s content anywhere. `KONTEXT.md` is the single source of truth for domain vocabulary.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in, if the directory exists.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest
creating them upfront. The `/domain-modeling` skill creates them lazily when terms or decisions
actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (a hypothesis, a strategy family, a backtest result, an
issue title), use the term as defined in the glossary section of `KONTEXT.md`. Don't drift to
synonyms an entry's `*Avoid*:` line explicitly rules out.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing
language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding.

## Single-context

This is a single-context repo: one glossary (`KONTEXT.md`) at the root, no `CONTEXT-MAP.md`,
no per-package contexts.
