# JOURNAL – Tagebuch des Trading-Bot-Projekts

> Ein Eintrag pro Tag (neuester oben). Jede Arbeitssitzung ergaenzt den
> Tageseintrag: Was wurde gemacht, was kam heraus, was wurde entschieden,
> was ist offen. Zahlen-Details stehen in `backtests.csv`, der volle
> Kontext in `KONTEXT.md` – das Journal ist die Zeitleiste dazu.

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
