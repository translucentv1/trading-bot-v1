# Forschungs- & Betriebs-Spielplan

Label: wayfinder:map
Letzte Aktualisierung: 15.07.2026

## Destination

Ein abgestimmter Forschungs- & Betriebs-Spielplan (`spec.md`), der Arbeitssystem
(Claude-Setup, Skills, Tools, Repo-Struktur) *und* den Strategie-Prozess
(Idee -> Backtest -> Demo-Paper -> Freigabe) so festlegt, dass die Chance auf
einen robusten, echten Edge maximiert wird -- messbar an klaren Test- und
Promotion-Kriterien. Die Karte ist fertig, wenn nichts Grundsaetzliches mehr zu
entscheiden ist; gebaut/umgebaut/getestet wird danach.

## Notes

- **Domain:** Solo-MQL5-Forschungsrepo fuer MetaTrader 5. Stand: 121+ erfolglose
  FX/Gold-Backtests, 10 Strategie-Familien, j=ngster Domain-Pivot zu
  Nasdaq-Einzelaktien (Phase 4). Aktiver EA: `experts/ema_mtf_v3.mq5`.
- **Vokabular:** immer die Begriffe aus `KONTEXT.md` (Glossar) verwenden.
- **Skills je Session:** `/grilling` + `/domain-modeling` fuer Entscheidungs-
  Tickets; `/research` (Subagent) fuer research-Tickets.
- **Scope-Regel:** planen, nicht bauen. Diese Karte produziert Entscheidungen +
  den fertigen Spielplan. Der eigentliche Umbau von Repo/Tools/EA ist ein
  Folge-Vorhaben. Ausnahme: knappe `task`-Tickets, die genau eine Entscheidung
  testbar machen.
- **Kern-These:** 121 Nullnummern riechen nach Methodik (Overfitting), nicht nach
  falschem Markt. Ticket 05 (Test- & Overfitting-Protokoll) ist der Hebel.
- **Eiserne Regeln bleiben:** kein Martingale/Grid; Erwartung vor Trefferquote;
  Backtest -> Demo-Paper -> Live nur manuell durch den Nutzer.

## Decisions so far

<!-- ein Eintrag pro geschlossenem Ticket: knappe Gist + Link -->

- [01 Datenlage Nasdaq-Einzelaktien in MT5](issues/01-datenlage-nasdaq-mt5.md) --
  Einzelaktien nur als CFDs bei Offshore-Brokern; Historientiefe symbol-individuell
  und fuer Fenster A (2022-2023) NICHT garantiert; Split-/Dividenden-Verzerrung im
  Tester. Saubere, tiefe Daten nur beim Index US100/NAS100 (keine Einzeltitel).
  -> Marktfokus (04) und Broker-Realitaet (07) muessen das einpreisen.
- [02 Overfitting-Schutz-Methoden](issues/02-overfitting-schutz-methoden.md) --
  Pflicht-Minimum fuers Protokoll: (1) Walk-Forward + versiegeltes OOS (nativ MT5),
  (2) Robustheits-Heatmap + Parameter-Sparsamkeit (Plateau statt Peak), (3)
  Deflated Sharpe mit ehrlichem N aus backtests.csv. Erst Prozess-Schutz, dann
  Statistik; ohne mitgezaehltes N ist jede Korrektur wertlos. PBO/White = Kuer.
  -> direkte Vorlage fuer das Kernticket 05.
- [03 MT5-Backtest-Automatisierung](issues/03-mt5-backtest-automatisierung.md) --
  Headless-CLI geht: terminal64.exe /config:*.ini startet Tester-Lauf ohne Klicks,
  XML-Report; Sweeps via Optimization= + [TesterInputs]; Kompilieren via
  metaeditor64.exe /compile. Ein Skript-Loop ersetzt die Tester-Klicks; Handarbeit
  nur bei Demo-Server-Aussetzern. -> Entscheidung "wieviel Automatisierung schreibt
  der Plan fest?" ist jetzt scharf: neues Ticket 08.
- [05 Test- & Overfitting-Protokoll](issues/05-test-overfitting-protokoll.md)
  (KERN) -- Verbindliches Protokoll: (1) Rolling Walk-Forward IS:OOS 3:1, >=5
  Zyklen, WFE > 0,5, >=30 Trades/Param, versiegelte Lockbox; (2) max. 4 Parameter,
  Plateau-Pflicht (~20 %), Zappel = Durchfall; (3) Deflated Sharpe > 0,95 mit
  ehrlichem N pro Strategie-Familie, Hypothese-vor-Lauf (neue Spalte `hypothese`).
  Erfolgs-Tor = alle + PF-Korridor 1,1-1,4 (PF > 1,4 = Verdacht) + Lockbox haelt.
  Abbruch-Treppe fail-fast (Stufe 0-5) + HARKing-Budget ~15 Laeufe/Familie.
  -> entblockt Ticket 06.
- [06 Promotion-Gate](issues/06-promotion-gate.md) -- Backtest->Demo = 05er
  Erfolgs-Tor. Demo-Paper bestanden erst bei >= 3 Monaten UND >= 30 Trades UND
  Nicht-Kollaps (PF >= 1,0, < 30 % Degradation, DD < 50 % ueber Backtest).
  Demo->Live nur manuell + dokumentiert (JOURNAL.md), kleiner Ramp-up, eine
  Strategie zur Zeit. Rueckwaerts: Sofort-Abbruch bei Demo-Kollaps,
  Live-Rueckstufung, harter Kill-Switch (an Notausstieg-Regel), kein Martingale.
- [04 Marktfokus](issues/04-marktfokus.md) -- Gestaffelt: Stufe 1 = US100/NAS100
  (Index) als Validierungs-Sandkasten fuer das 05-Protokoll auf sauberen Daten;
  Stufe 2 (Phase-4b) = Einzelaktien-Korb als Folge-Vorhaben. Uebergangs-Trigger:
  Protokoll einmal end-to-end durchlaufen (Pass ODER ehrlicher Abbruch) UND
  Broker-/Symbol-Datencheck bestanden. FX/Gold ruht. -> Hypothesen-Pipeline (jetzt
  entblockt) graduiert zu Ticket 09.
- [08 Automatisierungsgrad](issues/08-automatisierungsgrad.md) -- Zielgrad: voller
  End-to-End-Loop (kompilieren -> .ini -> Lauf -> XML parsen -> backtests.csv ->
  validate). PowerShell-Orchestrator + Python-Auswertung in tools/. Robust:
  Plausibilitaetscheck + Retry + lautes Stoppen statt Muell; manueller Fallback bei
  Demo-Server-Aussetzern. Endet strikt vor Live. Bau = vorrangiges Folge-Vorhaben
  (planen, nicht bauen). -> Repo-Struktur graduiert zu Ticket 10.

## Not yet specified

<!-- in-scope Nebel, noch nicht scharf genug fuer ein Ticket -->

- Handoff-Fluss verfeinern (Claude Code <-> Claude Code; Gemini/GLM ausgeschlossen).
- Kapital-/Risiko-Sizing ueber die Eisernen Regeln hinaus.

## Out of scope

<!-- bewusst ausserhalb des Ziels; kehrt nur wieder, wenn das Ziel neu gezogen wird -->

- Der eigentliche Repo-Umbau / EA-Refactor -- Folge-Vorhaben, aus dem Plan abgeleitet.
- Live-Trading-Ausfuehrung -- bleibt manuell beim Nutzer (Eiserne Regel).
