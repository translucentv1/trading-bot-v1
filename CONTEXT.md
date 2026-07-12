# CONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 12.07.2026_

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Ziel: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
(Backtests bisher mit 10.000 USD / 1:33 gelaufen – Ziel-Setup fuer spaeter angleichen.)
Repo (privat): https://github.com/translucentv1/trading-bot-v1

## Aktueller Stand
Phase 2. **EA v2.0 ist die erste PROFITABLE Version** (Backtest 3:
PF 1,09, Netto +141,17 ueber 18 Monate). Edge noch duenn – naechster
Schritt: Robustheit pruefen / Parameter optimieren.

## Letzte Aktion
- **AI Studio:** Wiederherstellung und Validierung des Workspaces nach einer Git-Index-Reparatur.
- **EA v2.0 Implementierung:** Vollstaendige Erstellung und Ueberpruefung der `/experts/ema_9_21_crossover_long_v2.mq5` mit allen beschriebenen Features (Marktstruktur-SL, dynamischer TP, ATR-Trailing-Stop, RSI-Filter und risikobasiertes Lot-Sizing).
- **Handoff-Bereitschaft:** Alle Projekt-Dateien sind fehlerfrei lizensiert und kompiliert (React-Frontend und Express-Backend), der Workspace ist absolut sauber und bereit fuer die naechste Claude-Code-Sitzung.

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

## Naechste Schritte & Workflow fuer Claude Code (Phase 3 & 4)

Ziel: Den EA auf Zwei-Wege-Handel (Long & Short) aufzuruesten und das interaktive React-Frontend vollständig an die neuen, volatilitätsbasierten Parameter von v2.0 und v3.0 anzupassen.

### Schritt 1: Backtests & Parameter-Optimierung von EA v2.0 (Aktion im Terminal durch den Nutzer)
- **Kompilieren:** Die Datei `experts/ema_9_21_crossover_long_v2.mq5` im MetaEditor kompilieren.
- **Robustheits-Check:** Backtests ueber einen laengeren Zeitraum laufen lassen (z.B. 01.01.2022 bis heute auf EURUSD H4).
- **Optimierung:** Im Strategy Tester die Parameter `InpRewardRatio` (1.2 bis 2.5) und `InpTrailATRMult` (1.5 bis 3.5) optimieren, um die stabilsten Werte (Plateaus) zu identifizieren.

### Schritt 2: Implementierung von EA v3.0 (Zwei-Wege-Handel - Long & Short)
Claude Code soll eine neue Datei `/experts/ema_9_21_crossover_v3.mq5` erstellen, welche die vollwertige Short-Logik ergaenzt:
- **Short-Einstieg (Symmetrisch):**
  - Schnelle EMA (9) kreuzt langsame EMA (21) nach unten (`isDeathCross`).
  - **Trendfilter:** Kurs liegt unter der Trend-EMA (200) (`isTrendDown`).
  - **RSI-Filter:** RSI liegt ueber dem Ueberverkauft-Level (z.B. `InpRSIMinLevel = 30.0`), um nicht in erschoepfte Maerkte zu verkaufen.
- **Short-Risikomanagement:**
  - **Struktur-SL:** Stop-Loss ueber dem letzten Swing-Hoch (Maximum der High-Preise der letzten `InpSwingLookback` Kerzen) plus ATR-Puffer (`InpATRMult`).
  - **Dynamischer TP:** TP-Kurs = Einstiegskurs - (SL-Abstand * `InpRewardRatio`).
  - **Lot-Sizing:** Risikobasierte Lot-Berechnung identisch zum Long-Handel (1% Risiko vom Kapital bei SL-Treffer).
  - **Trailing-Stop:** Trailing-SL zieht nach unten nach, wenn der Kurs faellt (Bid + ATR * Trailing-Mult).

### Schritt 3: UI-Synchronisation im React-Frontend (`src/App.tsx` & `src/data.ts`)
Claude Code soll das Web-Dashboard aktualisieren, damit es mit dem erweiterten Funktionsumfang von v2.0 und v3.0 uebereinstimmt:
- **Neue Eingaberegler (Sliders/Inputs):**
  - **Swing Lookback:** Regler fuer Marktstruktur-Tiefe (z.B. 5 bis 20 Kerzen, Standard: 10).
  - **ATR Multiplikator:** Regler fuer SL-Puffer (z.B. 1.0x bis 3.0x, Standard: 1.5).
  - **Reward Ratio (CRV):** Regler fuer das Chance-Risiko-Verhaeltnis des TP (z.B. 1.0 bis 3.0, Standard: 1.8).
  - **Trailing ATR Mult:** Regler fuer den Trailing-Stop-Abstand (z.B. 1.5x bis 4.0x, Standard: 2.5).
  - **RSI-Filter Pegel:** Regler fuer RSI Max (Long) / RSI Min (Short) (Standard: 70 / 30).
- **Simulations-Logik (`src/data.ts`):**
  - Die Backtest-Simulations-Funktion `runSimulatedBacktest` anpassen, sodass sie die verfeinerten Logiken (Struktur-SL, dynamischer TP, RSI-Filter und Trailing-Stop) im Modell approximiert.

### Schritt 4: Aktualisierung des MQL5 Code-Generators im Frontend
- Das Template fuer den generierten Code im Tab "MQL5 Code" so umbauen, dass standardmaessig der vollstaendige Code von **EA v2.0** oder **v3.0** generiert wird, basierend auf den vom Benutzer eingestellten Reglern.
- Damit erhaelt der Benutzer direkt den optimierten und profitablen EA-Code zum Export.

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
