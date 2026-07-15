# Forschungs- & Betriebs-Spielplan

Stand: 15.07.2026 | Quelle: Wayfinder-Karte `map.md` (10/10 Tickets geloest)

Dieser Plan verdichtet die zehn Entscheidungen der Karte zu einem lesbaren Ganzen.
Er legt das **Arbeitssystem** (Repo, Werkzeuge, Skills) und den **Strategie-Prozess**
(Idee -> Backtest -> Demo-Paper -> Freigabe) so fest, dass die Chance auf einen
robusten, echten Edge maximiert wird. Gebaut/umgebaut/getestet wird nach diesem Plan,
nicht in ihm.

---

## 0. Leitgedanke

**Die 121 erfolglosen Backtests waren ein Methodik-Problem (Overfitting), kein
Markt-Problem.** Der gesamte Plan ist die Antwort darauf: erst die Disziplin, dann die
Strategie. Der teuerste Filter ist der billigste -- ein Satz Nachdenken vor dem Lauf
spart fuenf Walk-Forward-Zyklen hinterher.

Eiserne Regeln (unveraendert): kein Martingale/Grid; Erwartung vor Trefferquote;
Backtest -> Demo-Paper -> Live nur manuell durch den Nutzer; im Zweifel teurer rechnen.

---

## 1. Ideen-Eingang: Hypothesen-Pipeline (Ticket 09)

Kein zufaelliges Herumprobieren mehr. Jede Idee durchlaeuft:

1. **Eingangstor -- Mechanismus zuerst.** Vor jedem Lauf ein Satz: *Warum existiert
   dieser Edge -- wer verliert das Geld, das ich gewinnen will, und warum wiederholt?*
   Kein plausibler Mechanismus -> kein Backtest. Data-Mining/Screening ist erlaubt,
   aber ein Treffer ohne Mechanismus ist nur eine geparkte Kandidaten-Notiz.
2. **4-Feld-Format**, vor dem Lauf fix, danach unveraenderlich (Anti-HARKing):
   Mechanismus | Instrument+Richtung | vorhergesagtes Muster | Falsifikation.
   Wird das Muster nachtraeglich an die Daten angepasst -> Hypothese verbrannt.
3. **Priorisierung:** staerkster Mechanismus x billigste Widerlegung -- NICHT nach
   vermutetem Gewinn. Wahrheit vor Gewinn.
4. **Marktbindung:** jetzt nur Einzelinstrument-Mechanismen (Index), Querschnitt
   (relative Staerke etc.) erst in Phase-4b.

Ablage: kurzer Key in `backtests.csv` (Spalte `hypothese`) -> ausfuehrlicher Eintrag
in `hypothesen.md`.

---

## 2. Marktfokus: gestaffelt (Ticket 04)

- **Stufe 1 (jetzt): US100/NAS100 Index** als Validierungs-Sandkasten fuer das
  Protokoll auf sauberen, tiefen Daten.
- **Stufe 2 (Phase-4b): Einzelaktien-Korb** als Folge-Vorhaben.
- **Uebergangs-Trigger:** Protokoll einmal end-to-end durchlaufen (Pass ODER ehrlicher
  Abbruch) UND Broker-/Symbol-Datencheck bestanden.
- FX/Gold ruht.

Grund (Ticket 01): Einzelaktien gibt es in MT5 nur als CFDs bei Offshore-Brokern,
Historientiefe symbol-individuell und fuer Fenster A (2022-2023) nicht garantiert,
plus Split-/Dividenden-Verzerrung im Tester. Saubere Daten nur beim Index.

---

## 3. Test- & Overfitting-Protokoll (Ticket 05, KERN)

Verbindliches Rueckgrat, drei Pflicht-Ebenen (Ticket 02 lieferte das Minimum):

1. **Walk-Forward + versiegeltes OOS.** Rolling, IS:OOS 3:1, >=5 Zyklen,
   WFE > 0,5, >=30 Trades/Parametersatz, versiegelte Lockbox (nativer MT5-Forward-Modus).
2. **Robustheit + Sparsamkeit.** Max. 4 Parameter, Plateau-Pflicht (~20 %
   Nachbarschaft stabil), Zappeln = Durchfall.
3. **Deflated Sharpe > 0,95** mit ehrlichem N pro Strategie-Familie
   (verwandte Laeufe zaehlen voll), Hypothese-vor-Lauf.

**Erfolgs-Tor** (alle Pflicht): WFE > 0,5 ueber >=5 Zyklen; Robustheit; DSR > 0,95;
PF-Korridor 1,1-1,4 (PF > 1,4 = Verdacht); Lockbox haelt.

**Abbruch-Treppe (fail-fast):**
- Stufe 0: >=30 Trades/Param, bevor ueberhaupt optimiert wird.
- Stufe 1: erster WF-Zyklus -- scharfer Peak -> raus.
- Stufe 2: erste OOS -- WFE <= 0,5 oder PF < 1,0 -> raus; PF > 1,4 -> pruefen;
  **Kosten-Ertrags-Schranke** (aus Ticket 07): Kosten > ~1/3 des Brutto-Edges/Trade
  -> raus.
- Stufe 3: >=5 Zyklen -- Zappeln -> raus.
- Stufe 4: DSR <= 0,95 -> raus.
- Stufe 5: Lockbox kollabiert -> raus.
- **HARKing-Budget:** ~15 Laeufe pro Strategie-Familie.

---

## 4. Broker-Realitaet im Test (Ticket 07)

Jeder Wertungs-Lauf preist die volle Realitaet ein; im Zweifel teurer:

1. **Ausfuehrungsmodell "jeder Tick auf realen Ticks"** ist Pflicht fuer jeden Lauf,
   der ins Erfolgs-Tor / DSR-N / die Lockbox zaehlt. Schnellere Modelle nur fuers
   Vorab-Sieben (Stufe 0), nie gewertet.
2. **Spread:** real variabel (kommt mit realen Ticks) + Stress-Zweitlauf mit ~1,5x
   fixem Spread. Bricht der Edge dabei -> Spread-Artefakt.
3. **Kommission & Slippage** explizit, konservativ, pro Instrument in der .ini-Vorlage
   (MT5 zieht beides nicht automatisch). Realwerte aus dem 04-Datencheck; solange
   unbekannt konservativ hoch.
4. **Kosten-Ertrags-Schranke** als Abbruch-Kriterium (siehe 3, Stufe 2).

---

## 5. Promotion-Gate: Backtest -> Demo -> Live (Ticket 06)

- **Backtest -> Demo:** exakt das Erfolgs-Tor aus Abschnitt 3.
- **Demo-Paper bestanden** erst bei ALLEM: >= 3 Monate UND >= 30 Trades UND
  Nicht-Kollaps (Demo-PF >= 1,0; < 30 % Degradation ggue. Backtest-PF; DD nicht
  > 50 % ueber Backtest-DD).
- **Demo -> Live:** nur manuell + dokumentiert in `JOURNAL.md`, kleiner Ramp-up,
  eine Strategie zur Zeit.
- **Rueckwaerts:** Sofort-Abbruch bei Demo-Kollaps; Live-Rueckstufung (PF < 1,0 ueber
  >= 20 Live-Trades -> zurueck zu Demo/Ruhestand); harter Kill-Switch an der
  Notausstieg-Regel; kein Martingale.

---

## 6. Automatisierungsgrad (Ticket 08)

- **Voller End-to-End-Loop, ein Kommando:** EA kompilieren (Compile-Log auf "0 errors")
  -> .ini aus Vorlage generieren -> Tester-Lauf starten und warten -> XML-Report parsen
  -> Zeile an `backtests.csv` -> `validate_backtests.py`.
- **Sprache/Ort:** PowerShell-Orchestrator + Python-Auswertung in `tools/`.
- **Robust:** Report-Plausibilitaetscheck (leer/kaputt -> KEINE CSV-Zeile), begrenzter
  Retry (2-3x), sonst lautes Stoppen ("Demo-Server/Daten pruefen"). Manueller Fallback
  bleibt der dokumentierte Ausnahmefall.
- **Grenze:** endet strikt vor Live. Automatisiert wird nur Backtest/Optimierung.
- **Bau = vorrangiges Folge-Vorhaben** (planen, nicht bauen).

Basis (Ticket 03): headless-CLI ist machbar -- `terminal64.exe /config:*.ini`
(ShutdownTerminal=1, XML-Report), Sweeps via `Optimization=` + `[TesterInputs]`,
`metaeditor64.exe /compile` (kein zuverlaessiger Exit-Code -> Log parsen).

---

## 7. Repo-Struktur & Werkzeuge (Ticket 10)

Eine Ebene Ordnung, nicht mehr (Solo-Repo):

- **tools/pipeline/** buendelt den Loop: `run_backtest.ps1`, `parse_report.py`,
  `backtest.ini.template`, DSR-/WF-Auswerteskript. Alt-Helfer (`validate_backtests.py`,
  `pool_backtests.py`, `run_cointegration.sh`, `checklist_new_strategy.md`) bleiben flach.
- **backtests.csv +4 Spalten:** `hypothese` (Key), `phase` (sieben/wf-is/wf-oos/
  lockbox/stress), `wf_zyklus`, `dsr`. Kosten-/Fenster-Details NICHT als Spalten
  (stehen in .ini bzw. `zeitraum`).
- **hypothesen.md** im Root als Forschungs-Register (4-Feld-Format aus Abschnitt 1).
- **Report-Ablage:** Roh-XML + generierte .ini gitignored (`reports/`); Heatmap-Belege
  eines Schluessellaufs versioniert (`reports/heatmaps/`).
- **Skills kuratiert:** Kern behalten -- wayfinder, grilling, domain-modeling, research,
  handoff; Engineering-Hygiene -- diagnosing-bugs, git-guardrails-claude-code,
  setup-pre-commit; entfernen -- setup-matt-pocock-skills, grill-me, grill-with-docs;
  Altlast raus -- `AI_STUDIO_PROMPT.md`.
- **Synchron-Halten** (CLAUDE.md) bleibt: `EA_CODE.md` spiegelt aktive .mq5; nach jedem
  Backtest `backtests.csv` + validate; jede Session `KONTEXT.md` + `JOURNAL.md`.
  Neu einzupflegen: KONTEXT-Glossar um Walk-Forward, WFE, Lockbox, Deflated Sharpe,
  HARKing-Budget; `hypothesen.md` in denselben Rhythmus.

---

## 8. Folge-Vorhaben (nach diesem Plan, ausserhalb der Karte)

In Reihenfolge:

1. **Pipeline bauen** (Abschnitt 6/7) -- ohne sie laeuft nichts anderes praktikabel.
2. **backtests.csv** um die 4 Spalten erweitern, `hypothesen.md` anlegen,
   KONTEXT-Glossar ergaenzen.
3. **Repo aufraeumen** gemaess Abschnitt 7 (tools/pipeline/, reports/, Skill-/Altlast-
   Bereinigung).
4. **Ersten Hypothesen-Zyklus** auf US100 fahren -- das Protokoll einmal end-to-end,
   um es (und den Uebergangs-Trigger zu Phase-4b) scharf zu stellen.

Offene Detailfragen, die erst hier geklaert werden (kein Karten-Ticket mehr):
Handoff-Fluss-Feinschliff (Claude Code <-> Claude Code) und Kapital-/Risiko-Sizing
ueber die Eisernen Regeln hinaus.
