# CLAUDE.md

MQL5 Expert Advisors fuer MetaTrader 5 — im Strategy Tester gebacktestet, dann
auf einem Demo-Konto paper-getradet. Solo-Forschungsrepo, ein Kontext.

## Aufbau
- `experts/*.mq5` — EAs (Nutzer kompiliert im MetaEditor). Aktiver Haupt-EA:
  `experts/ema_mtf_v3.mq5`.
- `scripts/*.mq5` — Hilfsskripte (Cointegration-Checks, Symbol-Finder).
- `tools/` — Python: `validate_backtests.py`, `pool_backtests.py`,
  `checklist_new_strategy.md`.
- `backtests.csv` — eine Zeile pro Backtest-Lauf; Header definiert die Spalten.

## Synchron halten (gleicher Commit)
- `EA_CODE.md` spiegelt die aktive `.mq5` wortgleich.
- Nach jedem Backtest: `backtests.csv`-Zeile ergaenzen, dann
  `tools/validate_backtests.py` laufen lassen.
- Jede Sitzung: `KONTEXT.md` (Stand/Chronik) und `JOURNAL.md` (Zeitleiste)
  aktualisieren.

## Konventionen & Verweise
- `.mq5` und `.md`: Deutsch, keine Umlaute (ae/oe/ue) — Zeichensatz-Sicherheit.
- Fachsprache, Eiserne Regeln, Projektstand -> `KONTEXT.md`.
- Skill-Konfiguration (Issue-Tracker, Domain-Docs) -> `docs/agents/*.md`.
