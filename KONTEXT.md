# KONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 14.07.2026 (Lernprojekt-Abschluss Phase 1-4, Phase 5 eroeffnet)_

## Letzte Aktion (14.07. – Lernprojekt-Abschluss + Phase 5 eroeffnet)
Weg B gewaehlt: Phase 1-4 sauber abgeschlossen. **`ABSCHLUSS.md`** neu
(ehrliche Retrospektive: 10 Familien-Tabelle, 7 belegte Lektionen,
bleibender Werkzeugkasten, Sicherheit). README auf Endstand aktualisiert
(163 Backtests / 10 Familien, Test-Disziplin um Beta-Kontrolle + Kosten
erweitert). **Phase 5 eroeffnet** (siehe Roadmap unten): naechste, strukturell
ANDERE Signalfamilie mit Leitplanken; Empfehlung Cross-Sectional Momentum
(beta-immun testbar). Kein Code fuer Phase 5 gebaut - wartet auf Nutzer-Wahl
der Richtung. Kein Demo-/Live-Einsatz.

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Ziel: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
(Backtests bisher mit 10.000 USD / 1:33 gelaufen – Ziel-Setup fuer spaeter angleichen.)
Repo (privat): origin = github.com/translucentv1/trading-bot (nicht mehr -v1).

## Mit-Arbeiter und Rollen (S2-Klaerung, 13.07.)
- **Claude Code** = schreibt Code, Git, Dateien, faehrt Backtests per CLI
  (voller Terminal-/Repo-Zugriff).
- **GLM-5 / "ZCode"** = derselbe zweite Agent (Planung, Audits, Reviews,
  ebenfalls Terminal-/Repo-Zugriff). "ZCode" ist ein Alt-Name fuer GLM-5.
- **AI Studio** = reine Strategie-/Diskussions-Rolle, **KEIN** Repo-Zugriff
  (bekommt Dateien eingefuegt, siehe AI_STUDIO_PROMPT.md).

## Backtest N (Chronik) <-> CSV-id Mapping (S4-Klaerung)
"Backtest N" in der Chronik ist NICHT die CSV-id! Zuordnung:
BT1=id1 | BT2=id? (Fruehphase) | BT3=id1(v2.0) | ... | BT8=id23-26 (OOS) |
BT9=id27-30 (GBPUSD/Gold) | BT10=id31-33 (VolFilter) | BT11=id34-35 (GBPUSD-VF) |
BT12=id38-49 (Struktur-Swing-Korb) | BT13=id50-61 (ORB-Korb).
Die frueheren BT4-7 (EURUSD 2025-2026, Zeitebenen) verteilen sich auf
id4-16. Im Zweifel: Chronik-Text lesen, nicht die id raten.

## Aktueller Stand
**Phase 4: Domain-Pivot zu US-Aktien (13.07.).**
Nach 121 FX/Gold-Backtests ohne robusten Edge -> Pivot auf Nasdaq-Aktien.
MetaQuotes-Demo bietet ~984 Nasdaq-Symbole (alle A-Anfang) + 15 FX + 1 Index
(AUS200). Historiedaten VERFUEGBAR und im Tester funktional bestaetigt.

**Stock Mean-Reversion EA (`stock_mr_v1.mq5`) getestet (Backtest 17+18) –
z>2-Befund durch Data-Snooping-Audit (Backtest 19) WIDERLEGT:**
- Strategie: RSI(2) Oversold-Bounce, Long-Only, SMA(200)-Trend-Filter, ATR-Stop.
- Getestet auf 10 liquide US-Aktien (AAPL, AMD, AMZN, AVGO, ADBE, ABNB, AXP,
  ABT, AIG, AEP) ueber 2 Fenster (A: 2022-2023, B: 2024-2026).
- **Der urspruengliche "z=2.46"-Befund entstand durch nachtraegliches Streichen
  der 2 schlechtesten Symbole (AMZN, AIG) NACH Sichtung der Ergebnisse.** Das
  ist Selection Bias. Auf dem sauberen, a-priori 10er-Pool (kein Streichen)
  bleibt KEIN robuster Edge:
  | Konfig | Fenster A (z / PF) | Fenster B (z / PF) | Gesamt |
  |---|---|---|---|
  | RSI<5, 10 Sym (sauber) | -0.42 / 0.90 | **+1.47 / 1.35** (n.s.) | z=0.85 |
  | RSI<5, 8 Sym (gesnoopt) | -0.18 / 0.95 | +3.55 / 2.18 | z=2.47 |
  | RSI<10, 10 Sym (sauber) | -1.33 / 0.76 | +2.54 / 1.44 | z=1.14 |
- **Beweis Selection Bias:** Der gewaehlte 8er-Pool (streiche AMZN+AIG) liefert
  in Fenster B z=3.55 = das MAXIMUM aller 45 moeglichen Streich-Paare. Es wurde
  exakt die Kombination gewaehlt, die z maximiert.
- **Kein Erfolgskriterium erfuellt:** |z|>2 in BEIDEN Fenstern wird von keiner
  Konfig erreicht. Fenster A ist ueber ALLE 45 Teilpools negativ (kein
  Streich-Artefakt -> im Baeren-/Seitwaerts-Regime kein Edge). Fenster B ist
  positiv, aber (a) fuer RSI<5 nicht signifikant (z=1.47) und (b) mit
  Long-Beta konfundiert (Long-only + SMA200-Filter = "im Bullenmarkt long").
- **AUS200 (Index-CFD):** kein Edge (PF 0.06-0.51).

Stand: **163 Backtests, 10 Strategie-Familien. Weiterhin KEIN robuster,
regime-unabhaengiger Edge (z>2-Befund war Selektions-Artefakt).**
**Kontroll-Experiment Weg A (Backtest 20) bestaetigt: Strategie ist Long-Beta,
kein Timing-Alpha.** -> Empfehlung: Weg B (Lernprojekt-Abschluss) oder
grundlegend andere Signalquelle. Kein Demo-Paper mit Gewinnerwartung.

**PHASE 2 (PAIR-TRADING) GEBAUT UND DURCHGEFALLEN
(13.07.):** `experts/pair_trading_v1.mq5` gebaut (Multi-Symbol, rollierende
Hedge-Ratio, Spread-z-Score, Kosten-Check, risikoneutrale Lots) und ueber
die 2 cointegrierten Paare x 2 Fenster x 3 ZEntry (12 Laeufe, id 62-73)
getestet. **Erfolgskriterium (gepoolt |z|>2 UND PF>1 in BEIDEN Fenstern)
NICHT erfuellt:** Fenster B (out-of-sample, 2024-2026) ist bei jedem ZEntry
negativ (PF 0,94-0,95). Das einzige |z|>2 (Fenster A, z2.5) traegt allein
AUDUSD~USDCAD - EURUSD~GBPUSD (das *staerker* cointegrierte Paar!) verliert
in JEDER Konfig. Und das ist die **obere Schranke** (Tester degradiert das
Sekundaersymbol -> real schlechter). Details unten: "Backtest 14".

**PHASE-1-GATE war bestanden (13.07.):** Cointegration-Pre-Check fand 2
cointegrierte Paare (EURUSD~GBPUSD ADF -5,43, AUDUSD~USDCAD -3,70). Das
Gate war statistisch korrekt - aber Cointegration im Sample != handelbarer
OOS-Edge nach Kosten (die zentrale Lektion aus Backtest 14).
Dabei 1 Bug gefixt (Cointegration-Zaehler zaehlte NOT_COINTEGRATED mit)
und mehrere Audit-Inkonsistenzen bereinigt (S1/S3/S5/S6 u.a.).

**Vorgeschichte (bleibt gueltig): 121 Backtests, 9 Strategie-Familien - kein
statistisch belegter, instrumentuebergreifend robuster Edge.** Carry-Basket
(Backtest 16) ohne Edge; Saisonalitaet (Backtest 15) ohne Edge; Pair-Trading (Backtest 14) faellt OOS durch; ORB
verliert signifikant (Backtest 13, z=-2,61); Struktur-Swing = Rauschen
(Backtest 12);
- Ein **strukturell anderer EA** (`structure_swing_ea.mq5`, Fractal-Swings
  + MTF-Trend, kein Indikator) gebaut UND mit der neuen **Pooling-Methodik**
  (Korb aus 6 Instrumenten, alle Trades gepoolt) getestet. Ergebnis:
  gepoolt PF 0,97 (A) / 0,88 (B), z -0,23 / -1,08 -> **kein Edge**
  (Backtest 12). Einzel-Symbole reines Rauschen (XAUUSD PF 2,2 vs AUDUSD 0,15).
- **DER eigentliche Fortschritt:** Die Pooling-Methodik loest das
  Stichprobenproblem - mit N~500 pro Fenster koennen wir Ideen jetzt
  statistisch SAUBER verwerfen statt an zu wenigen Trades zu scheitern.
- Bisher (bleibt gueltig): EMA-Kreuz, MTF-Bias, Gewinnsicherung,
  Mean-Reversion, Volatilitaetsfilter - alle ohne robusten Edge.
- **Konsequenz:** KEIN Feintuning bekannter Ideen, kein Live-Einsatz mit
  Gewinnerwartung. Jede kuenftige Idee wird gepoolt ueber den Korb geprueft
  (Ziel gepoolt |z|>2, PF>1 in BEIDEN Fenstern). Die EMA9/21- wie die
  Swing-Struktur-Idee sind damit sauber ausgeschieden.

## Letzte Aktion (13.07. – Data-Snooping-Audit Stock-MR, Backtest 19)
Auftrag: den "erstmals z>2"-Befund (Stock-MR) auf Selection Bias pruefen,
BEVOR irgendein Demo-Schritt erwogen wird. Ergebnis: **Der Befund haelt nicht.**
- **1) Audit (wie wurden die 8 Symbole gewaehlt?):** Nachweislich NACHTRAEGLICH
  und performance-abhaengig. JOURNAL-Zitat vom selben Tag: "Konsistente Loser:
  AMZN (immer PF<0.7), AIG (beide Fenster negativ)" -> genau diese 2 wurden aus
  dem 10er-Pool entfernt. Kein a-priori-Kriterium. = Data Snooping.
- **2) Sauberes Kriterium (vorab festgelegt):** Pool = ALLE a-priori getesteten
  10 Symbole, ohne performance-basiertes Streichen. (10 > die gesnoopten 8, also
  zugleich der groessere Pool.) Kriterium fuer kuenftige Erweiterung dokumentiert
  in checklist_new_strategy.md-Sinne: liquideste N A-Ticker nach Stichtags-Volumen,
  VOR dem Test fixiert.
- **3) Re-Test (Neu-Poolen der vorhandenen Laeufe id 122-161, Methode identisch
  zu tools/pool_backtests.py, kein neuer Tester-Lauf noetig):** siehe Tabelle in
  "Aktueller Stand" und Backtest 19. Kein |z|>2 in beiden Fenstern.
- **4) Mehrfachtest:** 163 Backtests / 10 Familien; allein in DIESER Familie 45
  8er-Teilpools x 2 Varianten x 2 Fenster. Ein einzelnes |z|>2 ist unter so vielen
  Versuchen zu erwarten. 9/45 (RSI<5) bzw. 29/45 (RSI<10) der 8er-Pools "erreichen"
  z>2 in Fenster B allein durchs Weglassen -> das ist Rauschen im Selektionsspielraum.
- **5) Fenster-Diskrepanz:** Signifikanz nur in Bull-Fenster B, Fenster A
  durchgehend negativ. Wahrscheinlichste Erklaerung: Long-Beta, nicht ein echter
  Mean-Reversion-Timing-Edge (nicht sauber trennbar ohne Buy&Hold-Benchmark).
  Spricht eher GEGEN robusten Edge als fuer eine saubere Regimeabhaengigkeit.
- **6) Kosten:** MetaQuotes-Demo-Aktien-CFDs modellieren vermutlich keine
  realistische Kommission (~0,005 USD/Aktie) -> der gemessene Edge/Trade von nur
  ~6-7 EUR ist gegen realistische Reibung duenn. Verifikation offen, aber nicht
  entscheidungsrelevant (Ablehnung steht schon aus 1-5).
- **7/8) Konsequenz:** KEIN Demo-Paper mit Gewinnerwartung. Vorschlag: entweder
  EIN entscheidendes Kontroll-Experiment (Signal vs. Buy&Hold-/Zufalls-Beta auf
  denselben Symbolen/Fenstern), um zu klaeren ob ueberhaupt Timing-Edge existiert,
  ODER Projekt als dokumentiertes Lernprojekt abschliessen. Details unten.

## Letzte Aktion (13.07. – Domain-Pivot + Stock MR)
- **Symbol-Finder gebaut:** `experts/symbol_finder.mq5` + `scripts/add_symbols.mq5`.
  Broker (MetaQuotes-Demo) hat 12.672 Symbole: ~984 Nasdaq-Aktien/ETFs (A-Range),
  15 FX, 1 Index-CFD (AUS200), Rest DISABLED. Gold (XAUUSD) NUR als FX-Kreuzpaar.
- **stock_mr_v1.mq5 gebaut:** RSI(2) Mean-Reversion, Long-Only, SMA(200)-Filter,
  ATR-Stop. Kompiliert 0 errors. Korb von 10 US-Aktien getestet (42 Laeufe,
  id 122-163 in backtests.csv).
- **Ergebnis:** Erstmals z > 2 im Gesamtpool (z=2.46 bei 8 Symbolen, RSI<5).
  Fenster B (Bull) sehr stark (z=3.53), Fenster A (Bear) neutral (z=-0.18).
  Regime-bedingter Edge, kein Allwetter-Signal.
- **Naechster Schritt:** Entscheidung ob (a) Demo-Paper mit Regime-Bedingung,
  (b) weiteres Tuning (laengerer Haltezeitraum, H4 statt D1), oder
  (c) dritter OOS-Zeitraum (2020-2021 mit COVID-Crash + Recovery).

## Letzte Aktion (13.07. – Audit + P1-Konsistenz-Fixes)
ZCode (dritter Mit-Arbeiter) hat das Repo einer objektiven Pruefung
unterzogen, um von einem sauberen, konsistenten Stand weiterzuarbeiten:
- **Validierung:** `tools/validate_backtests.py` -> "Keine Abweichungen"
  (alle 61 Zeilen intern konsistent). `EA_CODE.md`-Codeblock = exakt
  die aktive `.mq5` (675 = 675 Zeilen, gleicher Commit).
- **P1-Fixes umgesetzt** (nur Kosmetik/Konsistenz, keine Logikaenderung):
  (a) Versions-Stempel im EA korrigiert - Datei-Header und OnInit-Print
  sagten noch "v3.0", `#property version` steht aber auf 3.50. Beide
  auf v3.50 gesetzt (inkl. EA_CODE.md).
  (b) README veraltet: "35+ Backtests" -> "61 Backtests ueber 6
  Strategie-Familien"; aktive Version v3.41 -> v3.50.
- **P0 Sicherheit ERLEDIGT (Nutzer, 13.07.):** Die Remote-URL enthielt
  ein eingebettetes GitHub-Token. Vom Nutzer bereinigt auf
  `https://github.com/translucentv1/trading-bot-v1.git` (kein Token
  mehr); Authentifizierung laeuft jetzt ueber `credential.helper =
  manager` (Windows Credential Manager).
- **P2 Beobachtung (kein Handlungsbedarf):** `OnTester()` schreibt
  risk_realized_pct/z_score nicht selbst; entstehen im Python-Skript
  (dokumentiert, funktioniert). Automatisierung spaeter moeglich.
- **Protokollierung-Pflicht erfuellt:** dieser Abschnitt + JOURNAL-
  Eintrag (13.07.) + Backtest-Register bleibt aktuell.

## Letzte Aktion (12.07. spaet – Struktur-EA + Pooling)
Zwei Prompts umgesetzt (Strategen-Diagnose + YouTuber-EA-Spec):
- **Diagnose:** Das Kernproblem ist die zu kleine Stichprobe (z waechst mit
  sqrt(n); ~400 Trades noetig fuer |z|=2) PLUS wahrscheinlich kein echter
  EMA-Edge PLUS zu enge Suche (immer dasselbe Signal). -> Loesung: anderes
  Signal + Trades ueber Instrumente poolen.
- **Gebaut:** `structure_swing_ea.mq5` (Fractal-Swings + MTF-Trend, kein
  Indikator; non-repaint; Visuals; alle 6 YouTuber-Nachrichten umgesetzt;
  OnTester; Effizienz-Guard). Kompiliert 0 errors.
- **Getestet (Pooling-Methodik):** Korb aus 6 Instrumenten, Fenster A/B,
  N~500 -> kein Edge (gepoolt PF<1, z negativ; Backtest 12). Idee sauber
  verworfen. Pooling-Rahmenwerk funktioniert (ist der eigentliche Fortschritt).

## (frueher) Letzte Aktion (12.07. abends – Selbst-Review-Sitzung)
Eigenstaendige, objektive Ueberpruefung der gesamten Arbeit:
- **`tools/validate_backtests.py`** gebaut: rechnet z_score,
  risk_realized_pct, PF- und Netto-Konsistenz fuer ALLE Zeilen unabhaengig
  nach. Ergebnis: alle bisherigen manuellen Eintraege korrekt; z-Scores
  fuer id 1-22 nachgetragen (jetzt lueckenlos).
- **Zwei eigene Fehler gefunden + korrigiert:** (1) id 31-35 waren
  faelschlich auf 2026-07-13 datiert (richtig: 12.07.); (2) ein Semikolon
  im Fazit-Text haette die CSV zerschossen - Skript bricht jetzt vor dem
  Schreiben ab und schreibt atomar (Temp-Datei).
- **XAUUSD-Sizing-Bug GEFIXT (v3.41)** und mit Regressions-/
  Verifikationslauf belegt (id36/37, s. Nachtrag Backtest 9).
- **JOURNAL.md eingefuehrt** (Tagebuch, Pflicht in CLAUDE.md verankert),
  README.md komplett auf Forschungsstand aktualisiert, CLAUDE.md-Phasen
  aktualisiert (Phase 3 = Forschungsphase).
_Aeltere Sitzungs-Zusammenfassungen: siehe JOURNAL.md (Zeitleiste) und
Backtest-Chronik unten._

## Methodische Notizen (aus dem Selbst-Review, wichtig fuer Bewertungen)
1. **Nur Verlust-Strategien sind statistisch signifikant.** Nach
   Vervollstaendigung aller z-Werte: |z|>2 erreichen ausschliesslich
   M15/M30- und Mean-Reversion-Laeufe mit NEGATIVEM Vorzeichen (z -2,2
   bis -3,6). Der beste positive Lauf (VolFilter Gesamt, id31) hat z=1,69.
   Heisst: Was NICHT geht, ist belegt; fuer "geht" gibt es keine Evidenz.
2. **Multiple Testing:** Nach ~37 Varianten-Tests ist es wahrscheinlich,
   zufaellig "gute" Fenster zu finden. Einzelne gute Zahlen (z.B. id31/32)
   duerfen deshalb NICHT als Beweis gelesen werden - genau darum gilt die
   Regel OOS-Fenster + Zweitinstrument + |z|>2.
3. **Ueberlappende Zeitraeume:** "Gesamt"-Laeufe (2022-2026) enthalten
   Fenster A+B; sie sind KEINE unabhaengige Evidenz zusaetzlich zu A/B.

## Backtest-Chronik

### Backtest 1 – Ohne Trendfilter (11.07.2026)
- EURUSD H4, 01.01.2026–11.07.2026, 10.000 USD, 1:33
- Netto-PnL: -170,80 | Profitfaktor: 0,67 | Trefferquote: 10,53 % (2/19)
- Fazit: Zu viele Fehlsignale in Seitwaerts-/Abwaertsphasen.

### Backtest 2 – Mit Trendfilter EMA 200 (12.07.2026)
- EURUSD H4, 01.01.2026–11.07.2026, 10.000 USD, 1:33
- Netto-PnL: -286,94 | Profitfaktor: 0,04 | Trefferquote: 20 % (1/5)
- Max. Drawdown: 3,76 % | Trades: 5 (Filter reduzierte 19 → 5)
- Groesster Verlust: -202,86 (Stop-Loss ~234 Pips entfernt)
- **Kernproblem:** SL/TP aus "% vom Kontostand" starr in Kursabstand
  umgerechnet → kein Bezug zur Volatilitaet. SL viel zu weit, TP (~468
  Pips) nie erreicht. 4 kleine Gegenkreuz-Verluste + 1 grosser SL-Treffer.

### Backtest 3 – EA v2.0 (12.07.2026) – ERSTE PROFITABLE VERSION
- EURUSD H4, **01.01.2025–11.07.2026 (18 Monate)**, 10.000 EUR, 1:33
- **Netto-PnL: +141,17 | Profitfaktor: 1,09 | Erwartung: +5,23/Trade**
- Trefferquote: 40,74 % (11/27) | Trades: 27
- Ø Gewinntrade: +156,62 | Ø Verlusttrade: -98,85 (CRV 1,58:1)
- Groesster Gewinn: +184,94 | Groesster Verlust: -107,12
- Max. Drawdown: 5,99 % (Konto) / 6,88 % (Equity)
- Sharpe: 0,58 | LR-Korrelation: +0,65 (Kapitalkurve steigt jetzt)
- Max. Verlusttrades in Folge: 6 (-597,56) – der wunde Punkt
- **Vergleich v1.10 (gleiche 18 Mon.): Netto -313,59, PF 0,73.**
  Kernwende: nicht die Trefferquote, sondern das CRV. Struktur-Stops
  machten Verluste kleiner, dynamischer TP liess Gewinner groesser laufen.
- Hinweis: BT1/BT2 liefen nur ueber 6 Monate (2026), daher nicht 1:1
  vergleichbar; der 18-Monats-Zeitraum ist die neue Referenz.

### Backtest 4 – EA v3.0 Multi-Timeframe (12.07.2026), 18 Mon., 10.000 EUR
Neuer EA `ema_mtf_v3.mq5` (Long/Short, hoehere Zeitebene = Bias). H4-Bias.
| Zeitebene | Long+Short | nur Long |
|---|---|---|
| M15 | -5.656 (DD 59%) | -5.217 |
| M30 | -1.511 | -2.571 |
| H1  | -1.005 | **+519 | PF 1,11 | Sharpe 1,77 | DD 9,5% | 83 Trades** |
- **Bester Bestand: H1 + H4-Bias + long-only** (schlaegt v2.0 deutlich).
- M15/M30 zu verrauscht (Spread frisst kleine Bewegungen).
- Shorts schaden auf EURUSD (starker Aufwaertstrend 2025-26).
- Short-Faehigkeit bleibt als Toggle (InpAllowShort) fuer andere
  Instrumente/Regimes erhalten.

### Backtest 5 – v3.0 Robustheit 2022-2026 (4,5 Jahre), long-only
| Einstieg / Bias | Netto | PF | Sharpe | DD | Trades |
|---|---|---|---|---|---|
| H1 / H4 | +1686 | 1,12 | 1,87 | 14,7% | 240 |
| H4 / D1 | +447  | 1,12 | 0,87 | 9,4%  | 67  |
| D1 / W1 | -313  | 0,52 | -    | 3,1%  | 9 (zu wenig) |
- Beide profitablen Varianten haben den Vorteil ueber 4,5 Jahre gehalten
  (kein Zufall der letzten 18 Monate).
- **Position-Trading-Wahl: H4 + D1-Bias** (wenige lange Trades, DD 9,4%).
- H1 + H4-Bias ist renditestaerker, aber aktiver (mehr Trades, hoeherer DD).
- D1-Einstieg untauglich (zu wenige Signale).

### Backtest 6 – v3.1 Gewinnsicherung (Break-Even + Teil-TP), 2022-2026
| Konfig | Netto | PF | Sharpe | DD | Trefferquote | Trades |
|---|---|---|---|---|---|---|
| H4+D1 ohne Sicherung | +447 | 1,12 | 0,87 | 9,4% | 43% | 67 |
| **H4+D1 MIT Sicherung** | +385 | 1,12 | 0,99 | 7,2% | **68%** | 101 |
| H1+H4 MIT Sicherung | +250 | 1,02 | 0,37 | 17,8% | 65% | 345 |
- Break-Even (Stop auf Einstieg ab +1R) + Teil-TP (50% bei +1R).
- Auf H4: Trefferquote 43->68%, DD runter, Sharpe hoch, Gewinn leicht
  runter -> guter Deal fuer Position Trading (Wunsch des Nutzers).
- Auf H1 schaedlich (kappt die grossen Gewinner) -> dort Sicherung AUS.
- Wichtig (Realitaet): Edge (PF 1,12) ist robust, aber die ABSOLUTE
  Rendite haengt am Risiko/Trade (aktuell konservativ 1%). 10%/Monat wie
  im Marketing des fremden EA ist nur mit kontosprengendem Risiko
  erreichbar - nicht unser Weg.

### Backtest 7 – v3.2/3.3 Mean Reversion (M30) – LEHRSTUECK
Nutzer wollte Mean-Reversion-Einstiege auf M30 + hoehere Zeitebene als
Filter, "raus sobald im Plus" fuer maximale Trefferquote.
- MR mit Trend-Ausstieg (v3.2): alle negativ, wenige Trades (11-44).
- MR "raus sobald im Plus" (v3.3): Trefferquote 83-100 %, ABER netto
  MINUS (-182 / -249). Ø Gewinn +1,53 EUR vs Ø Verlust -99 EUR.
  Ein Verlust loescht ~65 Gewinne.
- **Kern-Lehre (mit eigenen Daten belegt): hohe Trefferquote != Profit.
  Was zaehlt ist die Erwartung (Groesse x Haeufigkeit), nicht die Quote.
  Genau die Falle hinter '90% Winrate / 10% pro Monat'-Marketing-EAs.**
- Fazit: zurueck zum bewiesenen H4-Trend + Gewinnsicherung (68% Quote,
  positive Erwartung). MR-Modi bleiben als Toggle im Code, aber aus.

### Backtest 8 – Out-of-Sample-Test (12.07.2026) – WENDEPUNKT
Zwei getrennte Fenster statt durchgehend, um Trendabhaengigkeit zu pruefen.
| Konfig | Fenster A 2022-2023 | Fenster B 2024-2026 | Urteil |
|---|---|---|---|
| H4+D1+Sicherung | +640, PF 1,65, 75% | **-245, PF 0,88, 64%** | NICHT robust |
| H1+H4 ohne Sich. | +1501, PF 1,25, 43% | **+153, PF 1,02, 41%** | haelt knapp |
- Die bisher "empfohlene" H4-Konfig verdient nur in 2022-2023 Geld, in
  2024-2026 Verlust -> die +385 ueber 2022-2026 waren ein Trend-Artefakt.
- H1-Konfig in beiden Fenstern positiv, aber Kante schrumpft (Sharpe
  3,49 -> 0,35). Kein starker, stabiler Vorteil.
- **Optimierung zurueckgestellt** (fragile Kante nicht ueberoptimieren).

### Aufgabe 3 – gleiche Trades? (Doku)
BT1 (v2.0, H4) und BT10 (v3.0, H4/D1) haben beide exakt 27 Trades und
40,74% (11 Gewinner). Sehr wahrscheinlich dieselben Einstiege: der
D1-Bias-Filter hatte 2025-2026 keine zusaetzliche Filterwirkung, weil
EURUSD durchgehend im Aufwaertstrend lief (beide Filter dauernd "an").
Der P&L-Unterschied (141 vs 86) stammt aus dem anderen Ausstiegs-Code
(v2.0 Trailing pro Kerze, v3.0 pro Tick), nicht aus anderen Einstiegen.

### Swap/Rollover (Doku, Aufgabe 5)
Tester laeuft mit realistischen Swaps: EURUSD MetaQuotes-Demo swap_long
-0,7 / swap_short -1,0 Punkte/Tag, Mittwoch dreifach. Bei "Jeder Tick"
werden sie am Rollover automatisch verrechnet (relevant fuer H4/D1-Halten).

### Backtest 9 – Multi-Instrument-Test (12.07.2026) – KANTE GENERALISIERT NICHT
H1-Einstieg/H4-Bias, ohne Sicherung, long-only, Fenster A/B, 10.000 EUR.
| Symbol | Fenster A 2022-2023 | Fenster B 2024-2026 | Urteil |
|---|---|---|---|
| EURUSD (Referenz) | +1501, PF 1,25 | +153, PF 1,02 | haelt knapp |
| GBPUSD (korreliert) | -258, PF 0,95 | -386, PF 0,95 | negativ |
| XAUUSD (Gold) | -5836, PF 0,51, DD 65% | -3985, PF 0,83, DD 47% | katastrophal |
- **Kern: Der Vorteil ueberträgt sich nicht mal auf das eng korrelierte
  GBPUSD.** Damit war der EURUSD-Gewinn hoechstwahrscheinlich Overfitting
  an EURUSD, kein echter Markt-Edge. Gold komplett ungeeignet.
- GBPUSD-Bestehen waere ohnehin nur ein schwaches Signal gewesen (hohe
  Korrelation) - es besteht nicht mal das.
- Lot/Risiko war sauber (GBPUSD 1,95 / XAUUSD 2,17 EUR pro min-Lot bei
  1,5xATR-Stop; Ziel 10 EUR) - der Fehlschlag liegt an der Strategie,
  nicht an der Testbarkeit.

### Nachtrag Aufgabe 1 (13.07.2026) – XAUUSD-Sizing-BUG entdeckt
Die XAUUSD-Zahlen (id 29/30) sind durch einen **Positionsgroessen-Bug
verzerrt** und NICHT bare Muenze zu nehmen:
- avg_loss XAUUSD = 3,73 %/3,77 % statt 1 % (Faktor ~3,75; GBPUSD sauber
  bei 0,93-0,95 %).
- Ursache: `SYMBOL_TRADE_TICK_VALUE` (nutzt CalcRiskLots) ist bei XAUUSD
  auf diesem Broker inkonsistent zur real verrechneten P&L (EA rechnet mit
  ~0,23 EUR/Tick, Tester realisiert ~0,87 EUR/Tick) -> Position ~3,8x zu
  gross. Log-Beweis: LONG Entry 2036,64/SL 2027,87/0,49 Lot -> realer
  SL-Verlust ~373 EUR.
- Zusatzeffekt: mehrere XAUUSD-Trades scheiterten mit "not enough money"
  (uebergrosse Position > Margin) -> weitere Verzerrung.
- KEINE Slippage/Gaps (Exits nah an erwarteten Levels), Modellierung
  "Jeder Tick" (aus M1 generiert).
- **Wichtig fuer die Schlussfolgerung:** PF und Trefferquote sind
  groessenunabhaengig -> Gold verliert weiterhin (PF 0,51/0,83), aber der
  "katastrophale" DD (65 %/47 %) war ein Sizing-Artefakt; bei korrekter
  1-%-Groesse waere DD ~17 %/13 %. GBPUSD unberuehrt, dortiges Fazit
  ("keine Kante", PF 0,95) bleibt voll bestehen.
- **ERLEDIGT (12.07. abends, v3.41):** Lotberechnung nutzt jetzt
  `OrderCalcProfit` statt `tick_value` (Fallback bleibt). Verifiziert:
  id36 EURUSD-Regression praktisch identisch zu id26 (+1,13 EUR Rundung);
  id37 XAUUSD Risiko 0,83 % statt 3,77 %, DD 13 % statt 47 %, keine
  Margin-Ablehnungen mehr (136 statt 88 Trades). Gold bleibt PF 0,94 < 1
  - sauber gemessen weiterhin kein Edge.

### Statistik-Check (Aufgabe 3, z-Werte fuer id 23-30)
Neue Spalten in backtests.csv: risk_realized_pct und z_score. Von den 8
Out-of-Sample-/Instrument-Laeufen ist **nur XAUUSD Fenster A (id 29,
z=-2,20) statistisch von Null verschieden** - und der haengt am Sizing-Bug
(Aufgabe 1), ist also kein echtes Signal. Alle anderen liegen bei |z| 0,1
bis 1,5 = **vom Rauschen nicht zu unterscheiden.** Heisst: weder die
"guten" (id 25 z=1,16) noch die "schlechten" EURUSD/GBPUSD-Ergebnisse sind
statistisch belastbar - die Stichproben sind zu klein / die Kante zu duenn.
Kuenftig risk_realized_pct + z_score bei jedem Lauf mitfuehren; Ziel fuer
ein echtes Signal: |z| deutlich > 2 bei sauberem 1%-Risiko.

### Backtest 10 – Volatilitaetsfilter (Aufgabe 4) – ERSTES VIELVERSPRECHENDES
Neuer Input InpUseVolFilter (default aus): Einstieg nur wenn ATR-D1 >=
rollierendem Median der letzten InpVolLookback=100 Tage. EURUSD H1/H4
long-only ohne Sicherung, mit vs ohne Filter:
| Zeitraum | OHNE (PF/Sharpe/DD/Trades/z) | MIT (PF/Sharpe/DD/Trades/z) |
|---|---|---|
| Gesamt | 1,12 / 1,87 / 14,7% / 240 / 0,86 | 1,37 / 5,13 / 7,5% / 120 / 1,69 |
| A 22-23 | 1,25 / 3,49 / 13,5% / 113 / 1,16 | 1,52 / 6,65 / 4,9% / 62 / 1,61 |
| B 24-26 | 1,02 / 0,35 / 13,8% / 127 / 0,12 | 1,23 / 3,34 / 6,3% / 58 / 0,76 |
- **Erstes Experiment, das ALLE Fenster konsistent verbessert** (kein
  Cherry-Picking): PF/Sharpe hoch, DD ~halbiert, z ueberall gestiegen.
- Wichtig: **Fenster B** (die OOS-Schwachstelle) klar besser - PF 1,02->
  1,23, z 0,12->0,76, 58 Trades (>50). Erfuellt die Erfolgskriterien.
- ABER ehrlich: z_B=0,76 ist immer noch < 2 -> **vielversprechend, aber
  noch KEIN statistisch bewiesener Edge.** Kein Abbruch-Kriterium erfuellt
  (A nicht schlechter, Trades nicht kollabiert, z gestiegen).
- Filter bleibt vorerst default AUS (nicht cross-instrument bestaetigt).

### Backtest 11 – Volatilitaetsfilter GBPUSD-Generalisierung – HAELT NICHT
Gleicher Filter (InpUseVolFilter=true, Lookback 100) auf GBPUSD H1/H4,
long-only, 10.000 EUR. Vergleich zur filterlosen Basis id27/id28:
| Fenster | Basis ohne Filter (PF/DD/z) | MIT Filter (PF/DD/z) |
|---|---|---|
| A 22-23 | id27: 0,95 / 8,62% / -0,24 | 1,08 / 6,09% / +0,23 (41 Tr) |
| B 24-26 | id28: 0,95 / 17,27% / -0,28 | 0,92 / 8,62% / -0,27 (46 Tr) |
- **Der Filter generalisiert NICHT.** Erfolgskriterium war "PF steigt in
  BEIDEN Fenstern + z klar besser". Auf GBPUSD steigt PF nur in A (leicht,
  1,08) - **Fenster B faellt sogar (0,92) und bleibt negativ**, z praktisch
  unveraendert (-0,27). Keins der GBPUSD-Fenster zeigt einen echten Edge
  (z nahe 0).
- Fazit: **Der Volatilitaetsfilter war ebenfalls im Wesentlichen
  EURUSD-spezifisch.** Die schoene EURUSD-Verbesserung (Backtest 10)
  ueberträgt sich nicht.

### Backtest 12 – Struktur-Swing-EA + Pooling-Methodik (12.07.2026)
NEUER, strukturell anderer EA `experts/structure_swing_ea.mq5`
(objektive Fractal-Swings + MTF-Trend, KEIN Indikator - Antwort auf die
"grundlegend neue Signalidee"). Getestet mit der neuen **Pooling-Methodik**
(Antwort auf das Stichprobenproblem): eingefrorene Konfig H1/H4, x3, y2,
max2, kein TP, ueber einen Korb aus 6 Instrumenten (EURUSD, GBPUSD, USDJPY,
AUDUSD, USDCAD, XAUUSD), Fenster A/B, alle Trades gepoolt.
| Fenster | Trades (N) | Netto | PF gepoolt | z gepoolt |
|---|---|---|---|---|
| A 2022-2023 | 477 | -1140 | 0,97 | -0,23 |
| B 2024-2026 | 518 | -4831 | 0,88 | -1,08 |
- **Ergebnis: kein Edge.** PF < 1 in beiden Fenstern, z nicht signifikant
  positiv. Einzel-Symbole voellig inkonsistent (XAUUSD PF 2,2 gegen AUDUSD
  PF 0,15) = Streuung von Rauschen, kein verteilter Vorteil.
- Auch der Struktur-Ansatz (x=5 -> 1 Trade in 2 Jahren; x=2 -> 350 Trades,
  -84 % DD; Mitte x3/y2 -> Whipsaw, 20 % Trefferquote) hat keinen Edge.
- **META-GEWINN (das eigentlich Wichtige):** Die Pooling-Methodik
  FUNKTIONIERT - mit N~500 konnten wir erstmals einen belastbaren z-Wert
  messen und eine Idee statistisch SAUBER verwerfen (statt "zu wenige
  Trades"). Das Test-Rahmenwerk ist jetzt aussagefaehig.

### Backtest 13 – Opening-Range-Breakout (Pooling) (12.07.2026)
Neuer Einstiegs-Modus 2 in `ema_mtf_v3.mq5` (v3.50): Ausbruch aus der
Spanne der ruhigen Session (0-8 Uhr EET, Serverzeit verifiziert = GMT+3
Sommer) + ATR-Puffer 0,2; 1 Versuch/Tag; Stop/TP/Trailing/Risiko
unveraendert. Isolierte Aenderung. Getestet ueber den 6er-Korb, Fenster A/B
(id 50-61).
| Fenster | Trades (N) | PF gepoolt | z gepoolt |
|---|---|---|---|
| A 2022-2023 | 2650 | 0,95 | -1,35 |
| B 2024-2026 | 3224 | **0,91** | **-2,61** |
- **Abbruch: kein Edge, sondern ein signifikant NEGATIVER.** PF<1 in
  beiden Fenstern; in B ist |z|=2,61 (>2) -> der ORB VERLIERT statistisch
  signifikant. Konsistent ueber fast alle Symbole (PF 0,85-1,06), also kein
  Rauschen: Fehlausbrueche + Spread kosten mehr als die Bewegungen bringen
  (FX-Opening-Ranges werden oft gefadet).
- Kontrast zur Swing-Baseline (Backtest 12): dort Streuung (PF 0,15-2,2,
  z ~0), hier konsistent negativ. Beide: kein verwertbarer Vorteil.
- Vorab-Check (Traderate): mit ~450-580 Trades/Symbol/Fenster war die
  Stichprobe mehr als ausreichend - die Aussage ist belastbar.

### Backtest 14 – Pair-Trading (Cointegration Phase 2) (13.07.2026) – OOS DURCHGEFALLEN
Neuer EA `experts/pair_trading_v1.mq5`: handelt den Log-Spread zweier
cointegrierter Symbole (Mean-Reversion auf z-Score). Rollierende Hedge-Ratio
(500 Bars, Look-Ahead-frei ab Index 1), Spread-Statistik ueber 100 Bars,
Einstieg bei |z|>=ZEntry, Ausstieg bei z->0 / Hard-Stop |z|>3,5 / Time-Stop
200 Bars, Kosten-Check (Erwartung > 2x Round-Turn), risikoneutrale Lots je
Bein 0,5 % via OrderCalcProfit. H1, Model "1 Min OHLC". Getestet ueber die
2 cointegrierten Paare x Fenster A/B x ZEntry {1,5; 2,0; 2,5} (id 62-73),
je Fenster gepoolt:
| ZEntry | Fenster A (in-sample) | Fenster B (out-of-sample) |
|---|---|---|
| 1,5 | PF 1,02  z=0,42 | PF 0,94  z=-1,45 |
| 2,0 | PF 1,07  z=1,19 | PF 0,95  z=-1,19 |
| 2,5 | PF 1,24  **z=3,01** | PF 0,94  z=-1,01 |
- **Kein robuster Edge.** Erfolgskriterium (gepoolt |z|>2 UND PF>1 in BEIDEN
  Fenstern) verfehlt: Fenster B ist bei jedem ZEntry negativ. Abbruch-
  Kriterium (Fenster-PF<0,95 ODER |z|<1,0) in Fenster B durchgehend erfuellt.
- **Lektion A - Cointegrationsstaerke sagt Handelbarkeit NICHT voraus:**
  EURUSD~GBPUSD war *staerker* cointegriert (ADF -5,43 vs -3,70), aber der
  *schlechtere* Trader (verliert in ALLEN 6 Konfigs, PF 0,91-0,97).
  AUDUSD~USDCAD trug das gesamte positive Signal - aber nur in-sample.
- **Lektion B - klassischer In-/Out-of-Sample-Bruch:** AUDUSD~USDCAD steigt
  in Fenster A mit ZEntry (PF 1,09->1,19->1,54), bricht in Fenster B aber
  immer ein (PF 0,94/0,92/0,99). Die rollierende Hedge-Ratio schwankt stark
  (EG 0,65 vs 1,56; AC -1,37) -> die Beziehung ist instabil, was gegen
  verlaesslich handelbare Cointegration spricht.
- **Lektion C - Kosten waren NICHT der Killer:** Round-Turn 2-9 EUR vs
  avg_win 29-125 EUR (~10-12 %, Kriterium <50 % erfuellt). Der Ansatz
  scheitert am fehlenden OOS-Signal, nicht an Reibung.
- **Caveat (verschaerft das Urteil):** MT5-Tester laedt volle Ticks nur fuers
  Chart-Symbol; das zweite Bein ist grob aufgeloest -> diese Zahlen sind
  eine OBERE SCHRANKE. Real waere es schlechter.
- Fazit: Pair-Trading auf diesen Paaren ist als Edge verworfen. Der EA
  bleibt als sauberes Multi-Symbol-Test-Geruest im Repo.

### Backtest 15 – Saisonalitaets-Filter (Session-Stunden) (13.07.2026) – KEIN EDGE
Neuer Toggle `InpUseSessionFilter` in `ema_mtf_v3.mq5` (v3.51): Einstiege nur
in einem a-priori Stundenfenster (Serverzeit EET), optional Montag/Freitag
aussparen. Rein zeitbasiert, voll im Tester testbar. Getestet: EMA-Kreuz
Long+Short ueber den 6er-Korb, Fenster A/B, **Basis (kein Filter) vs.
London/NY-Stunden 8-18 EET** (a-priori-Hypothese: hoechste Liquiditaet), je
gepoolt (id 74-97).
| Konfig | Fenster A (PF / z) | Fenster B (PF / z) |
|---|---|---|
| Basis (kein Filter) | 0,97 / -0,47 | **0,90 / -2,06** |
| Session 8-18 EET | 0,99 / -0,09 | 0,88 / -1,80 |
- **Kein Edge.** Der Filter hebt Fenster A nur marginal (PF 0,97->0,99, immer
  noch <1) und macht Fenster B sogar schlechter (0,90->0,88). z sinkt in B nur
  betragsmaessig, weil die Stichprobe halbiert wird (N 1567->797), nicht weil
  die Kante besser waere. Erfolgskriterium (PF>1 in beiden Fenstern, |z|>2)
  klar verfehlt.
- **Nebenbefund (wichtig): Die Basis EMA-Kreuz Long+Short verliert im Korb in
  Fenster B signifikant** (PF 0,90, z=-2,06) - konsistent mit ORB (Backtest
  13). Long+Short-EMA-Kreuz ist ueber den Korb ein statistisch signifikanter
  Verlierer, kein neutrales Nullsignal.
- GBPUSD einziges durchgehend positives Symbol (B: PF 1,16 Basis / 1,04
  gefiltert) - 1 von 6 = Rauschen/Overfitting, kein verteilter Vorteil.
- Filter bleibt als Toggle (default aus). Saisonalitaet als Edge-Quelle
  verworfen.

### Backtest 16 – Carry-Basket (Zins-/Swap-Differenz) (13.07.2026) – KEIN EDGE
Neuer EA `experts/carry_basket_v1.mq5`: haelt je Symbol die Seite mit dem
guenstigeren Swap (swap_long vs swap_short), weiter ATR-Schutzstopp (3x ATR-
D1), Richtung taeglich geprueft. Per-Symbol ueber den 6er-Korb (kein Multi-
Symbol -> keine Tester-Degradation). Zwei Varianten (id 98-121):
| Variante | Fenster A (PF / z / Netto) | Fenster B (PF / z / Netto) |
|---|---|---|
| Carry pur | 0,76 / -0,44 / -586 | 0,61 / -1,13 / -1674 |
| Carry + Trend (W1) | **1,45** / 0,62 / +702 | 0,87 / -0,41 / -256 |
- **Kein robuster Edge.** Pur: beide Fenster negativ. Mit Trend-Filter
  (Lehrbuch-Kombi Carry+Trend): Fenster A wird positiv (PF 1,45), aber
  Fenster B bleibt negativ (PF 0,87) -> derselbe In-/Out-of-Sample-Bruch.
- **Ergebnis von USDJPY dominiert** (A PF 6,96, B PF 5,08, aber nur 5-7
  Trades) - 1 Symbol von 6 = Rauschen, kein verteilter Vorteil. USDCAD
  durchgehend katastrophal (PF 0,18-0,23).
- **Zwei strukturelle Gruende:** (a) Retail-Swaps sind oft in BEIDE Richtungen
  negativ (Broker-Aufschlag) -> die "Carry-Einnahme" ist real negativ, es
  bleibt eine reine Richtungswette. (b) Zinsrichtung != Preisrichtung bei
  Trendassets (XAUUSD carry_diff -8 -> Short-Bias auf steigendes Gold,
  -1849 in B). Der Trend-Filter mildert (b), rettet aber B nicht.
- **Tester-Grenze:** SYMBOL_SWAP_* liefert im Tester statische (aktuelle)
  Swaps -> Carry-Richtung ueber den Backtest fix; niedrige Trade-Zahl
  (N 34-57) begrenzt die z-Power. PF-Urteil bleibt aber eindeutig.
- Carry verworfen. EA bleibt als Test-Geruest im Repo.

### Backtest 19 – Data-Snooping-Audit Stock-MR (13.07.2026) – z>2-BEFUND WIDERLEGT
Kein neuer Tester-Lauf, sondern eine objektive Nach-Analyse der vorhandenen
Stock-MR-Laeufe (id 122-161), weil der "erstmals z=2.46"-Befund auf einem
NACHTRAEGLICH auf 8 Symbole reduzierten Pool beruhte. Geprueft mit derselben
2-Punkt-Pooling-Methode wie tools/pool_backtests.py.

**Kernbefund: Der Edge ist ein Selektions-Artefakt.**
| Konfig | Fenster A (z / PF) | Fenster B (z / PF) | Gesamt A+B |
|---|---|---|---|
| RSI<5, **10 Sym (sauber, a-priori)** | -0.42 / 0.90 | **+1.47 / 1.35** | +0.85 |
| RSI<5, 8 Sym (ohne AMZN+AIG, gesnoopt) | -0.18 / 0.95 | +3.55 / 2.18 | +2.47 |
| RSI<10, **10 Sym (sauber)** | -1.33 / 0.76 | +2.54 / 1.44 | +1.14 |

- **Selection-Bias-Nachweis (Sensitivitaet ueber alle C(10,8)=45 Streich-Paare):**
  Fuer RSI<5 Fenster B ist der gewaehlte Drop (AMZN+AIG) mit z=3.55 das
  MAXIMUM der Verteilung (voller Pool z=1.47, Median der 45 Pools z=1.12).
  Man hat exakt die z-maximierende Kombination gewaehlt. 9/45 der 8er-Pools
  "schaffen" z>2 rein durchs Weglassen -> reines Selektionsrauschen.
- **Erfolgskriterium (|z|>2 in BEIDEN Fenstern) verfehlt.** Fenster A ist ueber
  ALLE 45 Teilpools negativ -> kein Streich-Artefakt, sondern echtes Fehlen
  eines Edges im Baeren-/Seitwaerts-Regime 2022-2023.
- **Fenster B (Bull) ist positiv, aber:** (a) fuer RSI<5 nicht signifikant
  (z=1.47), (b) mit Long-Beta konfundiert. Long-only + SMA200-Filter heisst
  "im Aufwaertstrend long kaufen" - in einem Bullenmarkt (B) verdient man damit
  auch ohne echten Timing-Edge. Ohne Buy&Hold-/Zufalls-Benchmark auf denselben
  Symbolen ist NICHT belegt, dass das RSI(2)-Timing etwas ueber das blosse
  Long-Sein hinaus beitraegt.
- **Mehrfachtest-Einordnung:** Bei 163 Backtests / 10 Familien und 45x2x2
  Auswertungsfreiheitsgraden allein hier ist ein einzelnes |z|>2 zu erwarten.
  Der Befund ist damit KEIN Beleg fuer einen Edge.
- **Kosten (Caveat, nicht entscheidungsrelevant):** Der gemessene Edge/Trade
  betraegt im besten sauberen Fall nur ~6-7 EUR (RSI<5 B: E=+6.39). Realistische
  Aktien-Reibung (Kommission ~0,005 USD/Aktie + Spread/Slippage), die die
  MetaQuotes-Demo als Stock-CFD vermutlich nicht voll abbildet, wuerde diese
  duenne, ohnehin nicht signifikante Ein-Fenster-Kante weiter erodieren.
- **Fazit:** Stock-MR RSI(2) zeigt KEINEN robusten, regime-unabhaengigen Edge.
  Der z=2.46-Befund war Data Snooping. EA bleibt als Test-Geruest im Repo.

### Backtest 20 – Kontroll-Experiment Weg A: Timing vs. Beta (13.07.2026) – TIMING SCHLAEGT BETA NICHT
Die Kernfrage aus Backtest 19: Traegt das RSI(2)-Timing ueberhaupt etwas bei, oder
ist der Bull-Fenster-Gewinn nur Long-Beta? Test-Aufbau: `experts/export_daily.mq5`
exportiert die D1-Serie + MT5-eigene RSI/SMA/ATR der 10 Aktien (10 headless
Tester-Laeufe); `tools/control_experiment.py` simuliert 3 Arme mit IDENTISCHEN
Exits (RSI>80 / 5 Tage / 3xATR-Stop), Kosten und Daten - nur der EINSTIEG variiert:
SIGNAL (RSI<Schwelle), BETA (immer long ueber SMA200), RANDOM (Zufallstage, 500
Seeds als Null). Validierung: der SIGNAL-Arm reproduziert die Tester-z-Werte (id
122-161), z.B. RSI<10 Fenster B z=+2.57 (Tester 2.54) - der Nachbau ist treu.

**Kernbefund: In KEINEM Fenster schlaegt das Timing die Beta signifikant.**
| RSI<10 (ohne Kosten) | Fenster A | Fenster B |
|---|---|---|
| SIGNAL z | -1.55 | +2.57 |
| BETA z | +0.65 | +2.90 |
| **z(Signal - Beta)** | **-1.67** | **+1.38** |
| Signal-Perzentil in Random-Null | 0 % (schlechter als Zufall) | 100 % (schlaegt Zufall) |

- **z(Signal-Beta) erreicht nie 2** (RSI<10: A -1.67, B +1.38; RSI<5: A +0.18,
  B +1.09). Das RSI(2)-Timing bringt keinen belegbaren Mehrwert gegenueber
  "einfach im Aufwaertstrend long sein". In Fenster A ist Signal sogar schlechter
  als der Zufall (0. Perzentil).
- **Nur schwacher Regime-Effekt:** In Bull-Fenster B liegt Signal ueber dem
  Random-Band (schlaegt Zufalls-Timing), in A nicht. Der Effekt ist also
  regime-gebunden UND verschwindet unter Kosten.
- **Kosten sind material (Schritt 6 beantwortet):** realistische Aktien-Reibung
  (Kommission max(0,005/Aktie;1$)/Seite + ~2bp Spread) frisst ~25-35 % der Kante.
  RSI<10 B SIGNAL: z 2.57 (ohne) -> 1.90 (real) -> 1.68 (pessimistisch). In
  Fenster A wird Signal mit Kosten signifikant negativ (z -1.99 real). Die
  MetaQuotes-Demo modelliert diese Kosten fuer Stock-CFDs vermutlich nicht.
- **Regime-Ursache (Chartanalyse):** Anteil Tage ueber SMA200 - Fenster A nur
  49 %, Fenster B 68 %. Die Long-only-Strategie hat in B strukturell viel mehr
  Rueckenwind. Das erklaert den Fenster-Unterschied ohne jeden Timing-Edge.
- **Schlussfolgerung: Die Strategie ist Long-Beta, kein Timing-Alpha.** Die
  Kernfrage ist damit sauber beantwortet. Kein Demo-Paper mit Gewinnerwartung.
- Visueller Report (Artifact, deutsch): Chartanalyse "Timing oder Long-Beta?"
  (Regime-Charts, Equity-Kurven, E/Trade-Vergleich, Kostenszenarien).
- Hinweis: Die 3 Arme sind Python-Re-Simulationen (validiert gegen die Tester-
  Laeufe), KEINE neuen Tester-Zeilen -> bewusst nicht in backtests.csv eingetragen.

## EA v2.0 – Was ist neu
1. **Marktstruktur-Stop:** SL unter das letzte Swing-Tief (Tief der
   letzten InpSwingLookback Kerzen) minus ATR-Puffer. Stop richtet sich
   nach echter Struktur statt nach starrem %.
2. **Dynamischer Take-Profit:** TP = Risiko x InpRewardRatio (1,8),
   passt sich dem Stop-Abstand automatisch an.
3. **ATR-Trailing-Stop:** zieht den SL bei Gewinn nach (InpTrailATRMult).
4. **RSI-Filter:** kein Kauf wenn RSI ueberkauft (> InpRSIMaxLevel = 70).
5. **Risikobasierte Lots:** Lotgroesse so berechnet, dass ein SL-Treffer
   genau InpRiskPerTradePct % (1 %) kostet – egal wie eng/weit der Stop.
6. Trendfilter (EMA 200) und Tagesverlust-Stopp bleiben erhalten.

## Naechste Schritte (Roadmap nach AI-Studio-Review, 13.07.)

**Vorbedingung:** AI-Studio-Review (docs/REVIEW_VERBESSERUNG.md) hat 7
Blindstellen im Pair-Trading-Plan identifiziert. Wichtigste: EURUSD/GBPUSD
sind wahrscheinlich NICHT cointegriert (Strukturbrueche Brexit, Gilt-Krise,
BoE-vs-ECB-Divergenz). MT5 Calendar API wurde uebersehen (News-Filter
funktioniert IM TESTER ohne externe Daten).

### Phase 1 – Cointegration-Pre-Check (GATE fuer Phase 2) – ERGEBNIS DA (13.07.)
Zwei Umsetzungen (S1 geklaert): `scripts/cointegration_check.mq5` = **Script**
(manuell, 1 Paar, auf Chart ziehen); `scripts/cointegration_check_ea.mq5` =
**EA** (laeuft im Tester via OnTester, rechnet ALLE 15 Kombinationen in
EINEM Lauf, schreibt `cointegration_all.txt`). Beide Engle-Granger OLS+ADF,
Look-Ahead-frei (Index ab 1). Fuer die Automatik wurde die EA-Variante
genutzt. Bugfix 13.07.: Zaehler zaehlte "NOT_COINTEGRATED" mit (Teilstring).

**Ergebnis (Symbol=EURUSD-Lauf, H1, Lookback 30000 ~4,3 J., 2022-2026):
2 von 15 Paaren cointegriert (1 %):**
| Paar | beta (Hedge) | ADF-t | Verdikt |
|---|---|---|---|
| **EURUSD~GBPUSD** | 0,9092 | **-5,43** | COINTEGRATED_1pct |
| **AUDUSD~USDCAD** | -0,9924 | **-3,70** | COINTEGRATED_1pct |
| USDJPY~USDCAD | 2,2915 | -2,86 | grenzwertig (nicht <5%) |
| die restlichen 12 | – | -0,26 bis -2,29 | NOT_COINTEGRATED |
(Krit. Werte MacKinnon: 1%=-3,43, 5%=-2,86, 10%=-2,57. Rohdaten:
`scripts/cointegration_result.txt`.)

**GATE-Entscheidung: cointegrierte Paare vorhanden -> Phase 2 ist
freigegeben** (Pair-Trading auf EURUSD~GBPUSD und AUDUSD~USDCAD). Laut
stehender Regel WARTET Claude Code aber auf Nutzer-Bestaetigung, bevor
Phase 2 (pair_trading_v1.mq5) gebaut wird.
**Status:** Phase 1 ABGESCHLOSSEN mit Ergebnis.

### Phase 2 – Pair-Trading-EA – ABGESCHLOSSEN, DURCHGEFALLEN (13.07.)
`experts/pair_trading_v1.mq5` gebaut (Multi-Symbol, rollierende Hedge-Ratio,
z-Score-Einstieg, Kosten-Check, risikoneutrale Lots, OnTester mit Pair-
Spalten). 12 Laeufe (id 62-73). Kein OOS-robuster Edge -> verworfen (Details
Backtest 14 oben). Naechster Ansatz: Phase 3 (Erweiterungen Haupt-EA).

### Phase 3 – Erweiterungen des Haupt-EAs (parallel zu Phase 2 planbar)
Jede als separater Toggle, isoliert testen, 6er-Korb, Fenster A/B:
- **3.1 MT5 Calendar API News-Filter — GEBAUT, aber im Tester NICHT testbar
  (13.07.).** Toggle `InpUseNewsFilter` + `IsNewsBlackout()` sauber im EA
  gekapselt (default aus). Eingebauter Vorab-Check in OnInit: `CalendarValue
  History()` liefert im Strategy Tester **0 Events** fuer historische Fenster
  -> Filter wirkungslos im Backtest (verifiziert EURUSD B: 0 Trades geblockt,
  identisch zum Lauf ohne Filter). Die Review-Annahme (Blindstelle 4,
  "Kalender im Tester verfuegbar") ist auf dieser MT5-Version falsch: der
  eingebaute Kalender haelt keine Jahres-Historie vor. Code bleibt fuer
  Demo/Live (dort ist der Kalender live da). Optionaler Weg fuer Backtests:
  historischen Kalender als Datei/Resource buendeln (bringt externe Daten
  rein - vorerst zurueckgestellt).
- **3.2 Saisonalitaets-Filter (Stunde/Wochentag) — GEBAUT UND GETESTET,
  KEIN EDGE (13.07., Backtest 15).** Toggle `InpUseSessionFilter` (default
  aus). London/NY-Stunden 8-18 EET vs Basis, gepoolt: verbessert nichts
  robust, Fenster B bleibt negativ. Verworfen.
- **3.3 Korb-Volatilitaetsregime** (offen)
- **3.4 Carry-Trade-Signal** (offen)

### weitere Ideen im Pool (falls Phase 2+3 scheitern)
Tick-Volume-Profile, Carry-Basket, Volatility-Expansion (preisbasiert,
NICHT ORB), Cross-Asset-Bestätigung via DXY. Details: REVIEW_VERBESSERUNG.md
Teil 4.

### Notausstieg
Nach insg. 100 Backtests ohne |z|>2 Edge: Pivot auf Indices, laengere
Haltedauer, manueller Discretion, oder Projekt als Lernprojekt abschliessen.

### Entscheidungsvorschlag nach Backtest 19 (13.07.) – zwei ehrliche Wege
Der einzige positive z>2-Befund des Projekts hat sich als Selektions-Artefakt
erwiesen. Stand: 163 Backtests, 10 Familien, weiterhin kein robuster Edge.
Empfehlung (Reihenfolge), Umsetzung entscheidet der Nutzer:

**Weg A – Kontroll-Experiment (ERLEDIGT 13.07., Backtest 20): NEGATIV.**
Das RSI(2)-Timing schlaegt "immer long ueber SMA200" (Beta) in keinem Fenster
signifikant (z(Signal-Beta) nie >2; in Fenster A negativ) und wird unter
realistischen Kosten unbrauchbar. Die Strategie ist Long-Beta, kein Timing-Alpha.
Die Kernfrage ist damit sauber beantwortet -> es bleibt nur noch Weg B.

**Weg B – Lernprojekt abgeschlossen (GEWAEHLT, 14.07.).**
Phase 1-4 sind sauber abgeschlossen, Retrospektive in `ABSCHLUSS.md` (10 Familien,
7 Lektionen, Werkzeugkasten). Der Ertrag ist methodisch: eine belastbare Pipeline,
die reihenweise Retail-Strategien statistisch widerlegt hat. Kein Demo-/Live-Einsatz
mit Gewinnerwartung. Der Nutzer will danach **bessere Strategien** versuchen ->
siehe "Phase 5 - Neue Signalfamilie".

**Nicht empfohlen:** Weiter-Tuning von Stock-MR (Haltedauer, H4, dritter Zeitraum)
BEVOR Weg A geklaert ist — das waere erneut Parameter-Jagd auf einem Signal ohne
belegten Edge. Ebenso KEIN Demo-Paper "nur im Bullenmarkt aktiv": das ist eine
ungetestete Regime-Wette auf einem konfundierten Ein-Fenster-Ergebnis.

### Phase 5 – Neue Signalfamilie (aktiv ab 14.07., "bessere Strategien")
Aufnahmepruefung (aus den 7 Lektionen, ABSCHLUSS.md): strukturell ANDERS,
Beta-/Zufalls-Benchmark von Anfang an, gepoolt + OOS (Pool vorher fixiert),
realistische Kosten. Kandidaten-Richtungen (Nutzer waehlt die erste):

- **(A) Cross-Sectional Momentum / Relative Staerke (EMPFEHLUNG).** Aus dem
  ~984er A-Aktien-Universum monatlich die staerksten N kaufen (relativ zum Korb).
  Cross-sectional Momentum ist eine der am besten dokumentierten Anomalien
  (Jegadeesh-Titman). Entscheidend: Edge wird als **Ueberrendite gegen den
  gleichgewichteten Korb** gemessen (beta-adjustiert) — genau die Disziplin, die
  in Phase 4 gefehlt hat. Voll im Tester + Python-Ranking abbildbar.
- **(B) Markt-neutral Long/Short.** Long Top-N, Short Bottom-N desselben Universums
  -> Beta per Konstruktion ~0, sauberster Alpha-Test. Voraussetzung: Shorten der
  Aktien-CFDs auf der Demo moeglich (pruefen). Anspruchsvoller.
- **(C) Volatility-Targeting / Risk-Parity auf dem vorhandenen Korb.** Kein neues
  Signal, sondern besseres Positions-Sizing (gleiche Risiko-Beitraege) — testet, ob
  Money-Management statt Signal den Unterschied macht. Kleinster Aufwand.
- **(D) Etwas ganz anderes** nach Nutzer-Idee (ereignis-/mikrostruktur-basiert),
  sofern im Tester ohne externe Daten pruefbar.

Empfehlung: mit **(A)** starten — beta-immun testbar, dokumentierter Struktur-Grund,
nutzt das grosse A-Universum als echte Querschnitts-Stichprobe.

## Kernregeln (Kurzfassung)
- Keine Kontodaten/Passwoerter/API-Keys in Code, Chat oder Commits
- Kompilieren + Strategy Tester: nur der Nutzer im MT5-Terminal
- Live-Trading: nur nach bestandenen Tests, nur durch den Nutzer
- Kommentare auf Deutsch, in .mq5-Dateien keine Umlaute (ae/oe/ue)

## Relevante Dateien
| Datei | Inhalt |
|---|---|
| experts/ema_mtf_v3.mq5 | **AKTIVE EA-Datei** (v3.50: EMA-Kreuz + MTF-Bias, Long/Short, Gewinnsicherung, Mean-Reversion-Modus, Vol-Filter, ORB-Modus 2, OrderCalcProfit-Sizing, OnTester) |
| experts/pair_trading_v1.mq5 | **Phase-2-EA (Pair-Trading):** Multi-Symbol Log-Spread-Mean-Reversion, rollierende Hedge-Ratio, z-Score, Kosten-Check, risikoneutrale Lots, OnTester mit Pair-Spalten; getestet Backtest 14, OOS durchgefallen |
| experts/carry_basket_v1.mq5 | **Carry-EA (Teil 4):** Zins-/Swap-Differenz je Symbol, ATR-Schutzstopp, optionaler Trend-Filter, per-Symbol-Korb; getestet Backtest 16, kein Edge |
| experts/structure_swing_ea.mq5 | Kandidat-EA (Fractal-Swings + MTF-Trend, non-repaint); getestet Backtest 12, kein Edge |
| experts/ema_9_21_crossover_long_v2.mq5 | alte v2.0 (nur Historie, nicht mehr aktiv) |
| scripts/cointegration_check.mq5 | **Phase 1 GATE (Script-Variante):** Engle-Granger OLS + ADF, EIN Paar, manuell auf Chart ziehen |
| scripts/cointegration_check_ea.mq5 | **Phase 1 GATE (EA-Variante):** rechnet ALLE 15 Kombinationen in EINEM Tester-Lauf via OnTester (fuer die Automatik genutzt) |
| scripts/cointegration_result.txt | Roh-Ergebnis des Cointegration-Laufs (13.07.): 2/15 Paare cointegriert |
| EA_CODE.md | kompletter aktueller EA-Code als Markdown (Handoff ohne .mq5-Upload) |
| docs/REVIEW_VERBESSERUNG.md | AI-Studio-Review: 7 Blindstellen + verbesserter Claude-Code-Prompt + 5 neue Ideen + Workflow mit Quality-Gates |
| backtests.csv | Register aller Backtests (121 Eintraege, id;...;risk_realized_pct;z_score;fazit) |
| JOURNAL.md | Tagebuch mit Tageseintraegen (Zeitleiste des Projekts) |
| tools/validate_backtests.py | objektive Nachrechnung/Validierung von backtests.csv |
| tools/pool_backtests.py | poolt Korb-Ergebnisse je Fenster, rechnet gepoolten z-Wert (Aufruf: prefix + verzeichnis) |
| experts/export_daily.mq5 | Datenexport-EA (D1-OHLC + RSI/SMA/ATR je Symbol -> Common\Files) fuer das Kontroll-Experiment |
| tools/control_experiment.py | **Weg A (Backtest 20):** Timing vs. Beta vs. Zufall, identische Exits/Kosten, 500-Seed-Null; liest tools/stock_export/ |
| tools/pool_from_csv.py | poolt beliebige Symbol-Teilmengen aus backtests.csv (Data-Snooping-Audit, Backtest 19) |
| tools/snoop_sensitivity.py | z-Verteilung ueber alle Streich-Paare (belegt Selection Bias, Backtest 19) |
| tools/stock_export/ | 10 exportierte D1-CSV (2022-2026) fuer control_experiment.py (standalone reproduzierbar) |
| tools/checklist_new_strategy.md | Checkliste fuer neue Strategie-Ideen (10 Punkte, Anhang B aus AI-Studio-Review) |
| AI_STUDIO_PROMPT.md | fertiger Prompt fuer AI Studio (inkl. gelernter Lektionen) |
| CLAUDE.md | Projektregeln + Handoff-Workflow |
| README.md | Projektueberblick + Setup + Test-Disziplin |
