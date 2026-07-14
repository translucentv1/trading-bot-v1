# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`KONTEXT.md`** at the repo root — this project's domain glossary (German). (This repo uses `KONTEXT.md`, not `CONTEXT.md`.)
- **`docs/adr/`** — read ADRs that touch the area you're about to work in, if the directory exists.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill creates them lazily when terms or decisions actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `KONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids (see each entry's `*Avoid*:` line).

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding.
