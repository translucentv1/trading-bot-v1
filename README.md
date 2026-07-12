# Trading-Bot: MQL5 Expert Advisor für MetaTrader 5

Ein Expert Advisor (EA) – ein Programm, das in MetaTrader 5 selbstständig
handelt. Er wird zuerst im **Strategy Tester** gebacktestet und läuft danach
automatisiert auf einem **Demo-Konto** (Spielgeld, kein echtes Geld):
Forex, Hedged, EUR, 1.000 EUR Startkapital, Hebel 1:30.

## Projektstruktur

```
experts/    MQL5-Quelldateien (.mq5) – werden im MetaEditor kompiliert
CLAUDE.md   Projektregeln
```

## EA in MetaTrader 5 einrichten

1. In MT5: **Datei → Dateiordner öffnen** → in den Ordner
   `MQL5\Experts\` wechseln und die `.mq5`-Datei aus `experts/`
   dorthin kopieren.
2. MetaEditor öffnen (Taste **F4** in MT5), die Datei im Navigator unter
   „Experts" doppelklicken und mit **F7 kompilieren** –
   unten muss „0 errors" stehen.
3. Backtest: in MT5 **Strg+R** (Strategy Tester) → EA auswählen →
   Symbol **EURUSD**, Zeitrahmen **H4**, Einzahlung 1.000 EUR,
   Hebel 1:30 → Start.
4. Paper-Trading: EA per Drag & Drop auf einen EURUSD-H4-Chart ziehen,
   oben den Knopf **„Algo Trading"** aktivieren. Der EA handelt dann
   selbstständig auf dem Demo-Konto, solange das Terminal offen ist.

## Aktuelle Strategie (v2.0)

`experts/ema_9_21_crossover_long_v2.mq5` – EMA-9/21-Crossover, nur Long, mit
markt-strukturbasiertem Risikomanagement:

- **Einstieg:** EMA 9 kreuzt EMA 21 nach oben, Trend bestätigt durch
  EMA 200, und RSI nicht überkauft (< 70).
- **Stop-Loss (Marktstruktur):** unter das letzte Swing-Tief (Tief der
  letzten Kerzen) plus ein Volatilitäts-Puffer (ATR). Der Stop richtet
  sich nach der echten Marktstruktur statt nach einem starren Prozentwert.
- **Take-Profit (dynamisch):** Risiko × Faktor (Standard 1,8). Zusätzlich
  zieht ein ATR-Trailing-Stop den Stop bei Gewinn nach.
- **Positionsgröße:** wird so berechnet, dass ein Stop-Loss-Treffer genau
  1 % vom Kapital kostet (risikobasiert).
- **Schutz:** Tagesverlust-Limit (Standard 5 %) schließt alles und
  pausiert bis zum nächsten Tag.

Alle Werte sind als Eingabe-Parameter änderbar (nach Gruppen sortiert).

**Verwendete Indikatoren:** EMA (9/21/200), ATR (Volatilität), RSI (Filter).

## Phasen

| Phase | Inhalt | Status |
|---|---|---|
| 1 | Struktur + erster EA mit Tagesverlust-Stopp | ✅ fertig |
| 2 | Backtests auswerten, Strategie verfeinern, Demo-Betrieb | offen |
| 3+ | Live frühestens nach bestandenen Tests, Entscheidung liegt beim Nutzer | offen |
