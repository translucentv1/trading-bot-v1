# Handoff: Wayfinder-Karte "Forschungs- & Betriebs-Spielplan" fortsetzen

_Erstellt: 2026-07-14 | Fuer: frische Claude-Code-Session | Fokus: Wayfinder weiterfuehren_

Zielumgebung ist Claude Code (die einzige Umgebung im Projekt neben dieser --
Gemini und GLM-5.2 sind ausgeschlossen). Die Wayfinder-/Grilling-/Domain-Modeling-
Skills stehen also zur Verfuegung; nutze sie direkt.

## Auftrag der naechsten Session

Die Wayfinder-Karte `forschungs-spielplan` weiter abarbeiten: die drei offenen
Entscheidungs-Tickets **04 (Marktfokus)**, **07 (Broker-Realitaet)**,
**08 (Automatisierungsgrad)** aufloesen -- je eines pro Session, breadth-first.
Ziel der Karte: ein abgestimmter Forschungs- & Betriebs-Spielplan, der
Arbeitssystem + Strategie-Prozess auf einen robusten Edge ausrichtet.

## Wo alles liegt (NICHT duplizieren -- lesen)

Repo: https://github.com/translucentv1/trading-bot-v1
Branch `claude/mql5-ea-nasdaq-setup-2a8b16` (gepusht auf origin, Commit `eb0d1ff`).
Alle Pfade relativ zur Repo-Wurzel:

- **Karte:** `.scratch/forschungs-spielplan/map.md` -- Destination, Notes,
  Decisions-so-far (5 Eintraege), Not-yet-specified, Out-of-scope. **Zuerst lesen.**
- **Tickets:** `.scratch/forschungs-spielplan/issues/NN-*.md`
  - 01/02/03 (research) = resolved, mit vollem `## Answer` (MT5-Datenlage Nasdaq,
    Overfitting-Methoden, Backtest-CLI-Automatisierung).
  - 05 (Kern) + 06 = resolved, mit vollem `## Answer` (Test-Protokoll,
    Promotion-Gate). Die Prozess-Seite des Plans ist damit fertig.
  - 04, 07, 08 = offen (`Status: open`), Blocker alle resolved -> alle startklar.
- **Domain-Glossar:** `KONTEXT.md` (Repo-Root) -- Fachsprache + Eiserne Regeln.
- **Tracker-Konventionen:** `docs/agents/issue-tracker.md` (Local Markdown) und
  `docs/agents/domain.md`. Wayfinder-Operationen im issue-tracker-Doc.
- **Versuchsregister:** `backtests.csv` (Header = Spalten; jede Zeile = 1 Backtest).

## So arbeitest du die Tickets ab (Wayfinder "Work through the map")

`/wayfinder` mit Karte + Ticketnummer starten. Ablauf je Ticket:
1. Karte laden (Low-Res), Ticket claimen: `Status: open` -> `claimed`, VOR jeder Arbeit.
2. Aufloesen per `/grilling` (eine Frage nach der anderen, jeweils Empfehlung geben;
   Fakten selbst nachschlagen, Entscheidungen dem Nutzer vorlegen).
3. `## Answer` ans Ticket anhaengen, `Status: resolved`, Kontext-Zeiger in `map.md`
   unter "Decisions so far".
4. Neu aufgetauchte Tickets anlegen / Nebel graduieren.
**Regel: nie mehr als ein Entscheidungs-Ticket pro Session** (research ausgenommen).

## Konventionen & Schutzvorgaben

- `.mq5`- und `.md`-Dateien Deutsch, KEINE Umlaute (ae/oe/ue).
- Eiserne Regeln (KONTEXT.md): kein Martingale/Grid; Erwartung vor Trefferquote;
  Backtest -> Demo-Paper -> Live nur MANUELL durch den Nutzer.
- Committen nur nach Rueckfrage (Nutzer gibt Go explizit).
- Nutzer ist Anfaenger, will eigenstaendige Arbeit + verstaendliche deutsche Berichte.

## Reihenfolge & was schon vorentschieden ist

1. **04 Marktfokus** (kurz): Research 01 hat es fast entschieden -- saubere, tiefe
   MT5-Daten nur beim Index US100/NAS100; echte Nasdaq-Einzelaktien nur als CFDs
   bei Offshore-Brokern mit unsicherer Historie + Split/Dividenden-Verzerrung.
   Erwartete Entscheidung: Index bestaetigen ODER Einzelaktien mit dokumentiertem
   Datenvorbehalt.
2. **08 Automatisierungsgrad:** Research 03 zeigt, headless-CLI geht (terminal64.exe
   /config, XML-Report, Sweeps, metaeditor64.exe /compile). Entscheidung: wie weit
   der Skript-Loop reicht; Bau selbst ist Folge-Vorhaben.
3. **07 Broker-Realitaet:** Pflicht-Kosten-/Slippage-Modellierung im Tester; haengt
   an konkretem Broker/Symbol aus 04.

Nach 04/08 graduiert Nebel: Repo-Struktur/Skill-Kuratierung, Hypothesen-Pipeline,
Handoff-Fluss (siehe `map.md` "Not yet specified").

## Offene Folge-Arbeiten aus 05/06 (planen, nicht bauen -- NICHT in die Tickets)

- Neue Spalte `hypothese` in `backtests.csv` (Anti-HARKing, ehrliches N).
- DSR-/Validate-Python-Skript in `tools/` (analog `validate_backtests.py`).
- `KONTEXT.md`-Glossar um neue Begriffe erweitern: Walk-Forward, WFE, Lockbox,
  Deflated Sharpe, HARKing-Budget (via `/domain-modeling`, separat).

## Suggested skills

- **wayfinder** -- "Work through the map" mit Karte + Ticketnummer.
- **grilling** -- Entscheidungs-Tickets 04/07/08 aufloesen.
- **domain-modeling** -- neue Begriffe ins `KONTEXT.md`-Glossar ueberfuehren.
- **research** -- nur falls ein neues research-Ticket auftaucht (aktuell keins offen).

## Zustand am Ende dieser Session

- Branch sauber, alles gepusht (origin, `eb0d1ff`).
- Nebenbei erledigt (separate Commits, nicht Teil der Karte): Skills auf 7 kuratiert,
  Token-Bloat ~24k gesenkt (`tools/bloat/README-messung.md`), trader-dev-MCP global
  entfernt (Backup: `~/.claude.json.backup-vor-trader-dev-2026-07-14`).
