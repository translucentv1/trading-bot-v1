# JOURNAL – Tagebuch des Trading-Bot-Projekts

> Ein Eintrag pro Tag (neuester oben). Jede Arbeitssitzung ergaenzt den
> Tageseintrag: Was wurde gemacht, was kam heraus, was wurde entschieden,
> was ist offen. Zahlen-Details stehen in `backtests.csv`, der volle
> Kontext in `KONTEXT.md` – das Journal ist die Zeitleiste dazu.

---

## 2026-07-13 (Tag 3) – Onboarding ZCode + Repo-Audit + Konsistenz-Fixes

**Kurzfassung:** ZCode ist als dritter Mit-Arbeiter (neben Claude Code
und AI Studio) eingestiegen. Erste Aktion: objektive Pruefung des
gesamten Repos auf Probleme und Inkonsistenzen. Ergebnis: Daten und
Tooling sind sauber, drei kleine Konsistenz-Fixes erledigt; ein
Sicherheits-Problem bleibt Nutzer-Aufgabe.

- **Audit durchgefuehrt:** `validate_backtests.py` -> "Keine
  Abweichungen" (alle 61 Eintraege konsistent). `EA_CODE.md` exakt
  synchron zur aktiven `.mq5` (675 Zeilen, gleicher Commit `a02b81a`).
  Git-Historie sauber (17 Commits, aussagekraeftige Messages).
- **P1-Fixes (nur Konsistenz, keine Logik):** EA-Versions-Stempel
  (Header + OnInit-Print) von "v3.0" auf "v3.50" korrigiert, in `.mq5`
  UND `EA_CODE.md`. README: "35+ Backtests" -> "61 ueber 6 Strategie-
  Familien", aktive Version v3.41 -> v3.50.
- **P0 Sicherheit ERLEDIGT (Nutzer, 13.07.):** Remote-URL enthielt ein
  eingebettetes GitHub-Token. Nutzer hat es bereinigt
  (`https://github.com/translucentv1/trading-bot-v1.git`, kein Token);
  Authentifizierung laeuft jetzt ueber `credential.helper = manager`.
- **P2 (kein Handlungsbedarf):** OnTester schreibt risk_realized_pct/
  z_score nicht selbst (entstehen im Python-Skript). Spaetere
  Automatisierung moeglich.

**Entscheidungen:** An allen etablierten Workflows festgehalten
(KONTEXT.md als Handoff, JOURNAL.md als Zeitleiste, Backtest-Pflicht,
EA_CODE.md-Sync-Regel). ZCode nutzt fuer den kommenden Pair-Spread-EA
das Claude-Code-Memory zum MT5-Workflow.

**Offen:** P0 Token-Rotation (Nutzer). Naechstes Vorhaben: Pair-Spread-
Mean-Reversion (neuer Modus) - ZCode legt zunaechst einen Plan vor.

**Nachmittag (AI-Studio-Review-Integration + Phase 1):**
- Nutzer hat AI-Studio-Review (`docs/REVIEW_VERBESSERUNG.md`) reingeliefert:
  7 Blindstellen im Pair-Trading-Plan, verbesserter Claude-Code-Prompt,
  5 neue strategische Ideen, Workflow mit Quality-Gates.
- Wichtigste Erkenntnis: EURUSD/GBPUSD sind wahrscheinlich NICHT
  cointegriert (Brexit, Gilt-Krise, BoE-vs-ECB). Pair-Trading-Blind
  gebaut ohne Cointegration-Pre-Check -> Phase 1 GATE noetig.
- MT5 Calendar API wurde uebersehen: News-Filter IST im Tester testbar.
- **Phase 1: Cointegration-Script gebaut** (`scripts/cointegration_check.mq5`).
  Engle-Granger OLS + ADF-Test, Look-Ahead-frei (Index ab 1), 0 Errors/0
  Warnings beim Kompilieren. Muss im MT5 auf den 6er-Korb geloest werden
  (15 Kombinationen). Ergebnis entscheidet ueber Phase 2 (Pair-Trading-EA).
- KONTEXT.md: Roadmap Phase 1->2->3 dokumentiert, Relevante-Dateien-Tabelle
  aktualisiert (neue Dateien, v3.50).
- AI_STUDIO_PROMPT.md: 7 gelernte Lektionen + Roadmap ergaenzt.
- Strategie-Checkliste (10 Punkte, tools/checklist_new_strategy.md) aus
  AI-Studio-Review Anhang B abgelegt.
- Compile-Log im Repo aufgeraeumt (kompiliert sauber).

---

## 2026-07-12 (Tag 2) – Der grosse Test-Tag: von "+141!" zu "kein belegbarer Edge"

**Kurzfassung:** 35 Backtests, 4 EA-Generationen, 2 harte Wahrheiten:
Die Strategie-Familie EMA-Kreuz+MTF-Bias hat keinen uebertragbaren,
statistisch belastbaren Vorteil – und hohe Trefferquote ist kein Profit.

- **v2.0 gebaut** (Marktstruktur-Stop, dynamischer TP, ATR, RSI, Risiko-Lots)
  nach Fehlschlag der %-SL-Versionen -> erster profitabler Lauf (+141, PF 1,09).
- **Backtest-Automatik eingerichtet** (Erlaubnis des Nutzers): Claude
  kompiliert und testet selbst per CLI, OnTester schreibt Kennzahlen,
  ~10-15 s pro Lauf. Stolpersteine geloest: Demo-Server-Disconnects beim
  Kaltstart (Retry), Tester-.set-Cache (Inputs greifen sonst nicht).
- **v3.0 Multi-Timeframe** (Long/Short, Bias-TF): H1+H4 long-only +519
  (18 Mon.) bzw. +1686 (4,5 J.); M15/M30 verlieren ueberall; Shorts
  schaden auf EURUSD; D1 zu wenige Trades.
- **v3.1 Gewinnsicherung** (Break-Even + Teil-TP): Trefferquote 43->68 %
  auf H4, DD runter – auf H1 schaedlich (kappt Gewinner).
- **v3.2/3.3 Mean-Reversion-Lehrstueck:** "Raus sobald im Plus" ergab
  83-91 % Trefferquote und trotzdem NETTO-MINUS (Oe Gewinn +1,5 EUR vs
  Oe Verlust -99 EUR). Mit eigenen Daten belegt: Trefferquote != Profit.
- **Out-of-Sample-Test (AI-Studio-Auftrag):** Die "empfohlene" H4-Konfig
  verdient nur 2022-2023, verliert 2024-2026 -> Trend-Artefakt. H1 haelt
  knapp (PF 1,02). Parameteroptimierung ZURUECKGESTELLT.
- **Multi-Instrument-Test:** GBPUSD (korreliert!) verliert in beiden
  Fenstern, XAUUSD katastrophal -> EURUSD-Gewinne waren Overfitting.
  Dabei XAUUSD-Sizing-Bug entdeckt (Position ~3,8x zu gross, tick_value
  unzuverlaessig) – DD-Zahlen dort Artefakt, PF<1 bleibt.
- **Volatilitaetsfilter (v3.4):** verbessert auf EURUSD ALLE Fenster
  (PF 1,37/1,52/1,23) – generalisiert aber NICHT auf GBPUSD (Fenster B
  PF 0,92). Also ebenfalls EURUSD-spezifisch.
- **Protokoll-Infrastruktur aufgebaut:** backtests.csv (Register aller
  Laeufe, inkl. risk_realized_pct + z_score), KONTEXT.md-Chronik,
  AI_STUDIO_PROMPT.md, EA_CODE.md (kompletter Code als Markdown).
- **Selbst-Review (Abendsitzung):** Validierungsskript
  `tools/validate_backtests.py` gebaut – rechnet alle Kennzahlen
  unabhaengig nach. Ergebnis: alle manuellen Eintraege korrekt; z-Scores
  fuer id 1-22 nachgetragen; Datumsfehler korrigiert (id 31-35 waren
  faelschlich auf 13.07. datiert). Sizing-Fix v3.41 (OrderCalcProfit
  statt tick_value) + Verifikationslaeufe. JOURNAL.md eingefuehrt.
  Git-Push-Haenger geloest (http.version auf HTTP/1.1).
- **Objektive Quintessenz der z-Werte:** Statistisch signifikant (|z|>2)
  sind NUR Verlust-Strategien (M15/M30, MR-Trend-Exit: z -2,2 bis -3,6).
  Kein einziger positiver Lauf erreicht z>1,7. Wir wissen sicher, was
  nicht geht – fuer "was geht" gibt es bislang keine belastbare Evidenz.
- **Spaetsitzung – Struktur-EA + Pooling-Durchbruch (Methodik):** Zwei
  Prompts umgesetzt (Strategen-Diagnose + YouTuber-Swing-EA-Spec).
  Diagnose: Hauptproblem ist die zu kleine Stichprobe – selbst ein echter
  kleiner Edge waere in unserem Rahmen (1 Instrument, 20-60 Trades) nie
  beweisbar. Konsequenz: neues Signal (Marktstruktur/Swings statt
  Indikator) UND Trades ueber einen Instrumenten-Korb POOLEN. Gebaut:
  `structure_swing_ea.mq5` (objektive Fractal-Swings, MTF-Trend, non-repaint,
  Visuals, alle 6 Nachrichten des YouTubers, kompiliert 0 errors). Getestet
  ueber 6 Instrumente, Fenster A/B, N~500: gepoolt PF 0,97/0,88, z
  -0,23/-1,08 -> KEIN Edge, Idee sauber verworfen (id 38-49, Backtest 12).
  Wichtig: Die Pooling-Methodik ist der eigentliche Fortschritt – erstmals
  koennen wir Ideen mit echter statistischer Aussagekraft verwerfen.
- **Opening-Range-Breakout (Session-Ansatz, v3.50):** Als Modus 2 in den
  Haupt-EA eingebaut (isolierte Einstiegs-Aenderung; Serverzeit vorher als
  EET/GMT+3 verifiziert). Gepoolt ueber den 6er-Korb (id 50-61): Fenster A
  z=-1,35/PF 0,95, Fenster B **z=-2,61/PF 0,91 bei N=3224** -> nicht nur
  kein Edge, sondern statistisch SIGNIFIKANT negativ und konsistent ueber
  fast alle Symbole (FX-Ausbrueche werden gefadet). Sauberer Abbruch.
  Damit sind heute 3 strukturell verschiedene Ansaetze (Swing-Struktur,
  Session-Breakout) zusaetzlich zu den 4 EMA-Familien belastbar verworfen.
  Housekeeping: tools/pool_backtests.py generalisiert (Prefix-Argument),
  Relevante-Dateien-Tabelle + Naechste-Schritte aktualisiert. Naechste
  Idee laut Strategen-Rolle: Mean-Reversion zwischen korrelierten Paaren.

**Entscheidungen:** Kein weiteres Tuning am EMA-Kreuz-Geruest. Kein
Live/Demo-Einsatz mit Gewinnerwartung. Naechster Schritt: grundlegend
neue Signal-Idee von AI Studio, geprueft nach dem strengen Muster
(OOS-Fenster + GBPUSD + Ziel |z|>2).

**Offen:** Neue Signal-Hypothese (AI Studio). GitHub-Token rotieren
(liegt im Klartext in .git/config – Aufgabe des Nutzers).

---

## 2026-07-11 (Tag 1) – Neustart auf MQL5/MetaTrader 5

- Projekt nach zwei frueheren Anlaeufen (Python/CCXT-Paper-Bot, dann
  TradingView/Pine + Python) auf **MQL5/MT5 als Hauptplattform** neu
  aufgesetzt. Repo-Struktur, CLAUDE.md-Regeln, README.
- **Phase 1 EA** gebaut: EMA-9/21-Crossover long-only (EURUSD H4) mit
  SL/TP in % vom Kapital und Tagesverlust-Stopp; alle Parameter als Inputs.
- **GitHub verbunden** (gh CLI, translucentv1), Repo privat gepusht.
- Sicherheits-Grundsaetze fixiert: keine Zugangsdaten in Code/Chat/Commits;
  Kompilieren/Tester beim Nutzer (spaeter per Erlaubnis automatisiert);
  Live nur durch den Nutzer nach dokumentierten Tests.
