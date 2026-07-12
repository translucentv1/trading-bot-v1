# KONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 12.07.2026_

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Ziel: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
(Backtests bisher mit 10.000 USD / 1:33 gelaufen – Ziel-Setup fuer spaeter angleichen.)
Repo (privat): https://github.com/translucentv1/trading-bot-v1

## Aktueller Stand
Phase 3. **ENTSCHEIDEND: Die Kante generalisiert NICHT ueber Instrumente.**
- H1+H4-Konfig (auf EURUSD die "robustere") getestet auf GBPUSD (hoch
  korreliert): **BEIDE Fenster negativ, PF 0,95 / 0,95.** Auf XAUUSD
  (Gold): **katastrophal, PF 0,51 / 0,83, DD bis 65 %.**
- Heisst: Der EURUSD-Gewinn war **im Wesentlichen an EURUSD (2022-2023)
  ueberangepasst** - kein echter, uebertragbarer Markt-Vorteil. Selbst das
  eng verwandte GBPUSD verliert.
- **Konsequenz: Parameteroptimierung bleibt zurueckgestellt; die
  EMA-Kreuz+MTF-Bias-Strategie hat (so) keinen generalisierbaren Edge.**
  Kein Live-Einsatz mit Gewinnerwartung. Naechster Schritt = anderer
  Ansatz oder Volatilitaets-/Regime-Filter, nicht Feintuning.
- Diagnose Fenster B: ~20 % geringere Volatilitaet (ATR-D1 0,0072 vs
  0,0090), Trendstaerke aehnlich -> kleinere Bewegungen, Kosten fressen
  die duenne Kante.

## Letzte Aktion
Multi-Instrument-Robustheitssitzung (Auftrag AI Studio). Aufgabe 0:
Remote `translucentv1/trading-bot` bestaetigt PRIVAT, Commit ffc6f8e drin
(Remote-Wechsel von -v1 nicht in git geloggt, beide privat = ok; Token
liegt im Klartext in .git/config -> Nutzer sollte ihn rotieren + auf
Credential-Manager/SSH wechseln). Aufgabe 1: Diagnose (Fenster B
volaarm). Aufgabe 2: Lot/Risiko fuer GBPUSD (1,95 EUR/min-Lot) und XAUUSD
(2,17 EUR) auf 1.000 EUR sauber testbar, EA rechnet generisch. Aufgabe
3/4: GBPUSD + XAUUSD getestet -> beide negativ (Details Backtest 9).
backtests.csv um Spalte `symbol` erweitert.

## (frueher) Letzte Aktion
EA v3.0 gebaut (Long & Short, Multi-Timeframe) und M15/M30/H1 automatisch
getestet. Ergebnis: M15/M30 verlieren (zu verrauscht); H1 gewinnt, aber
nur long-only (Shorts schaden, da EURUSD 2025-26 stark stieg). Wichtig
gelernt: der Tester cached Eingaben in `MQL5\Profiles\Tester\<ea>.set` –
Parameteraenderungen greifen nur, wenn diese .set geloescht/ueberschrieben
wird (sonst werden Compiler-Defaults ignoriert).

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

## Naechste Schritte (nach Multi-Instrument-Test)
Klarer Stand: **Die EMA-Kreuz+MTF-Bias-Strategie hat keinen
generalisierbaren Vorteil** (faellt auf GBPUSD und Gold durch). Deshalb:
1. KEINE Optimierung, KEIN Live-Einsatz mit Gewinnerwartung dieser
   Strategie - das waere Overfitting bzw. Selbsttaeuschung.
2. Grundlegend anderer Ansatz noetig. Optionen (mit AI Studio planen):
   - Volatilitaets-/Regime-Filter (nur handeln wenn ATR/Trend stark genug).
   - Ganz andere Signal-Idee (z.B. echte Ausbruchs-/Struktur-Logik mit
     Bestaetigung), sauber nach der Erwartungs-Logik (nicht Winrate).
3. Realistisch bleiben: Ein robuster, uebertragbarer Edge ist schwer;
   viele einfache Retail-Ideen haben schlicht keinen. Das ehrlich zu
   wissen ist wertvoller als eine schoen aussehende, ueberangepasste Kurve.
4. Der EA bleibt als solides, generisches Test-Geruest erhalten (Risiko,
   Sicherung, MTF, OnTester-Logging) - nur die Signal-Logik braucht Ersatz.
Jeder Lauf -> Zeile in `backtests.csv`.

## Kernregeln (Kurzfassung)
- Keine Kontodaten/Passwoerter/API-Keys in Code, Chat oder Commits
- Kompilieren + Strategy Tester: nur der Nutzer im MT5-Terminal
- Live-Trading: nur nach bestandenen Tests, nur durch den Nutzer
- Kommentare auf Deutsch, in .mq5-Dateien keine Umlaute (ae/oe/ue)

## Relevante Dateien
| Datei | Inhalt |
|---|---|
| experts/ema_9_21_crossover_long_v2.mq5 | EA v2.0 (Struktur-SL, dyn. TP, ATR, RSI) |
| CLAUDE.md | Projektregeln + Handoff-Workflow |
| README.md | Setup-Anleitung fuer MT5 |
