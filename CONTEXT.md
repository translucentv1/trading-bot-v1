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

## Naechste Schritte (nach BT3)
Ziel: die duenne Kante (PF 1,09) robuster und dicker machen.
1. ROBUSTHEIT: gleichen EA ueber laengeren Zeitraum testen (z.B. 2022–2026),
   um zu sehen ob der Vorteil ueber verschiedene Marktphasen haelt.
2. PARAMETER-OPTIMIERUNG im Strategy Tester (Reiter "Optimierung"):
   v.a. InpRewardRatio (1,4–2,6) und InpTrailATRMult (1,5–3,5).
   Achtung Overfitting – bevorzugt breite, stabile Bereiche statt Spitzen.
3. DRAWDOWN: 6 Verlust-Trades in Folge sind der Schwachpunkt; ggf. Filter
   verfeinern (z.B. Einstieg nur mit etwas Abstand ueber EMA200).
4. Danach: laengerer Demo-Beobachtungslauf (Paper) vor jeder Live-Idee.

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
