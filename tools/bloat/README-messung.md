# Token-Bloat messen (Claude Code System-Prompt)

Ziel: nachsehen, welche Tools/Skills/MCP-Server den Kontext am staerksten
aufblaehen, und nur nachweislich ungenutzte deaktivieren. Nach der Methode aus
https://www.aihero.dev/how-to-kill-the-bloat-in-claude-codes-system-prompt

## Baseline (14.07.2026, vor den Aenderungen)
`/context` in einer frischen Session ergab (Overhead ohne "Messages"):

| Kategorie | Tokens |
|---|---|
| System prompt | 3,3k |
| System tools | 11,6k |
| MCP tools | 9,3k |
| MCP tools (deferred) | 34,6k |
| System tools (deferred) | 15,5k |
| Memory files | 3,2k |
| Skills | 3,9k |
| **Overhead-Summe** | **~81,4k** |

Kernbefund: Der Bloat sitzt fast komplett im **MCP-Bereich (~59k)** —
v.a. `trader-dev` (~100 Tools), `claude-in-chrome` (~24), `Claude_Browser`
(~20), dazu `scheduled-tasks`, `mcp-registry`, `visualize`, `ccd_*`.
Skills sind mit 3,9k klein. Die settings.json-Schalter unten treffen NUR
Skills/Tools, nicht die MCP-Server — der grosse Hebel ist MCP (siehe unten).

## Proxy-Messung (durch den Nutzer, interaktive Session noetig)
Claude Code kann eine verschachtelte interaktive Session nicht selbst steuern —
diese Schritte bitte du selbst im Terminal ausfuehren:

1. Proxy starten (laeuft auf Port 8787, schreibt nach `./logs/`):
   ```
   node tools/bloat/proxy.mjs
   ```
2. In einem zweiten Terminal eine Claude-Code-Session an den Proxy haengen und
   eine normale Nachricht senden:
   ```
   ANTHROPIC_BASE_URL=http://localhost:8787 claude
   ```
3. Im ersten Terminal / in `tools/bloat/logs/` erscheint pro Request ein
   Markdown-Log, angefuehrt von einer **Rangliste** (Bytes + geschaetzte Tokens)
   je Tool/Block. Die groessten Zeilen sind die Kandidaten.

## Bereits gesetzt (.claude/settings.json, konservativ)
- `disableBundledSkills: true` — entfernt Anthropics gebuendelte Skills
  (docx, pdf, pptx, xlsx, dataviz, run, verify, loop, ... — fuer ein
  MQL5/Backtest-Repo ungenutzt). Slash-Commands bleiben nutzbar. Die kuratierten
  mattpocock-Projekt-Skills (in `.claude/skills/`) bleiben unberuehrt.
- `permissions.deny: ["NotebookEdit", "DesignSync"]` — definitiv ungenutzt
  (keine Jupyter-Notebooks, kein Design-Sync). Bare Toolnamen streichen das
  Tool ganz aus dem Payload.

## NICHT gesetzt (bewusst, wegen deiner Schutzvorgaben)
- `EnterPlanMode` — Plan-Mode bleibt (geschuetzt).
- `SendMessage` — Multi-Agent-Handoff bleibt (geschuetzt).
- `AskUserQuestion` — Rueckfragen bleiben.
- `disableWorkflows: true` — der Artikel nennt das den groessten Einzelposten,
  aber es koennte den Handoff/Workflow betreffen. **Erst nach Proxy-Messung**
  freischalten, wenn die Rangliste "Workflow" als grossen, ungenutzten Block
  bestaetigt. Dann in settings.json ergaenzen.
- `disableArtifact` — Artifacts koennten fuer deutsche Berichte nuetzlich sein;
  offen gelassen.

## Groesster Hebel (ausserhalb dieser Schalter): MCP-Server
~59k von ~81k Overhead sind MCP-Tool-Schemas. Wenn ein Server hier nicht
gebraucht wird, spart sein Entfernen ein Vielfaches der Skill-Tweaks:
- `trader-dev` (~100 Tools, ~35k) — Trading-MCP; vermutlich RELEVANT, behalten.
- `claude-in-chrome` + `Claude_Browser` — zwei Browser-Stacks; fuer
  MQL5-CLI-Backtests wahrscheinlich ungenutzt.
- `mcp-registry`, `scheduled-tasks`, `visualize`, `ccd_session_mgmt` — pruefen.

MCP-Server werden NICHT ueber settings.json abgeschaltet, sondern ueber die
MCP-Konfiguration (`claude mcp ...` bzw. `~/.claude.json`). Das ist eine
Infra-Entscheidung — bewusst hier nur dokumentiert, nicht angefasst.

## Nach den Aenderungen (gemessen 14.07.2026, nach Neustart)
`/context` in frischer Session, `trader-dev` aus `~/.claude.json` entfernt
(Backup: `~/.claude.json.backup-vor-trader-dev-2026-07-14`), settings.json-Schalter
aktiv. Die Session meldete: "49 deferred tools no longer available: DesignSync,
mcp__trader-dev__* (47), NotebookEdit" — alle drei Hebel greifen.

| Kategorie | Baseline | Nachher | Delta |
|---|---|---|---|
| System prompt | 3,3k | 3,3k | 0 |
| System tools | 11,6k | 15,9k | +4,3k |
| MCP tools | 9,3k | 8,9k | -0,4k |
| MCP tools (deferred) | 34,6k | 16,6k | **-18,0k** |
| System tools (deferred) | 15,5k | 9,9k | -5,6k |
| Memory files | 3,2k | 1,1k | -2,1k |
| Skills | 3,9k | 1,7k | -2,2k |
| **Overhead-Summe** | **~81,4k** | **~57,4k** | **~-24k** |

Kernergebnis: ~24k weniger Overhead pro Session. Groesster Einzelposten war
`trader-dev` (-18k im deferred-MCP-Block). Falls `trader-dev` je wieder
gebraucht wird: Backup zurueckspielen oder Server neu hinzufuegen.
