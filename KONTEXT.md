# KONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 12.07.2026_

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Ziel: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
(Backtests bisher mit 10.000 USD / 1:33 gelaufen – Ziel-Setup fuer spaeter angleichen.)
Repo (privat): https://github.com/translucentv1/trading-bot-v1

## Aktueller Stand
Phase 2. EA komplett ueberarbeitet auf **v2.0** – bereit fuer Backtest 3.

## Letzte Aktion
EA-Datei umbenannt in `ema_9_21_crossover_long_v2.mq5`, damit die neue
`.ex5` nicht mit der alten verwechselt wird. Hintergrund: Ein Testlauf
war versehentlich noch mit der alten v1.10-`.ex5` gelaufen (erkennbar an
alten Eingaben InpStopLossPct/InpTakeProfitPct + Kommentar "EMA Crossover
Long"). Neue Datei muss frisch mit F7 kompiliert werden.

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

### Backtest 3 – EA v2.0 (steht aus)
- Getestete Aenderungen (siehe unten). Parameter wie Backtest 1/2.
- Ergebnisse: [ noch einzutragen ]
  - Netto-PnL: [ ] | Profitfaktor: [ ] (vorher 0,04)
  - Trefferquote: [ ] | Trades: [ ] | Max. Drawdown: [ ]
  - Groesster Verlusttrade: [ ] (vorher -202,86)

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

## Naechste Schritte
1. NUTZER: Neue .mq5 aus experts/ in MQL5\Experts\ kopieren, F7 kompilieren
2. NUTZER: Strategy Tester – gleiche Parameter wie Backtest 1/2
3. NUTZER: Report als HTML speichern und teilen
4. KI: Auswerten, Parameter feinjustieren oder naechste Idee

## Ideen fuer danach (falls v2.0 besser, aber noch nicht gut genug)
- Testzeitraum auf 3+ Jahre ausweiten (mehr Trades, statistisch belastbar)
- Swing-Hoch als alternatives TP-Ziel statt fixem Reward-Faktor
- Zwei-Wege-Handel (echte Short-Logik) ergaenzen
- Parameter-Optimierung im Strategy Tester (RewardRatio, ATR-Mults)

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
