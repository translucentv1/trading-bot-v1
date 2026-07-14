# 07 -- Broker-Realitaet im Test: Kosten- & Slippage-Modellierung

Type: grilling
Status: open
Blocked by: 01

## Question

Welche Kosten- und Ausfuehrungs-Realitaet muss jeder Backtest verpflichtend
einpreisen, damit Scheingewinne auffliegen?
- Spread: fixer vs. realer variabler Spread im Strategy Tester -- welcher Modus?
- Kommission: pro Lot / pro Trade -- welcher Wert fuer die Ziel-Instrumente?
- Slippage-Annahme: pauschaler Aufschlag pro Trade?
- Ausfuehrungsmodell des Testers (jeder Tick / M1 OHLC / real ticks) -- welches ist
  Pflicht fuer belastbare Ergebnisse?
- Mindest-Trade-Zahl, damit Kosten die Statistik nicht dominieren.

Blockiert von 01 (Datenlage/Broker liefert die realen Kostenwerte).
