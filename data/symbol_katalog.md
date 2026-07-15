# Symbol-Katalog (Aktien-Korb)

Erstellt am: 15.07.2026
Broker: MetaQuotes-Demo (Terminal)

## 1. Broker-Kosten
Die Kostendaten wurden für alle 10 Symbole aus dem Korb per MetaTrader 5 `SymbolInfo` extrahiert.

| Symbol | Spread (Points) | Tick Value (USD) | Contract Size | Kommission |
|--------|-----------------|------------------|---------------|------------|
| AAPL   | 2               | 0.01             | 1.0           | 0.0*       |
| AMD    | 2               | 0.01             | 1.0           | 0.0*       |
| AMZN   | 2               | 0.01             | 1.0           | 0.0*       |
| AVGO   | 2               | 0.01             | 1.0           | 0.0*       |
| ADBE   | 2               | 0.01             | 1.0           | 0.0*       |
| ABNB   | 2               | 0.01             | 1.0           | 0.0*       |
| AXP    | 2               | 0.01             | 1.0           | 0.0*       |
| ABT    | 2               | 0.01             | 1.0           | 0.0*       |
| AIG    | 2               | 0.01             | 1.0           | 0.0*       |
| AEP    | 2               | 0.01             | 1.0           | 0.0*       |

*\* Hinweis zur Kommission:* `SymbolInfo` liefert auf diesem Broker keine direkte Trade-Kommission für Equities zurück. In der Realität können Kommissionen anfallen, im MetaQuotes-Demo-Server scheinen Spread (2 Cents) die Hauptkosten zu sein.

## 2. Historien-Verfügbarkeit
Es wurde per `CopyTicksRange` und `SeriesInfoInteger` geprüft, ab wann Daten bereitstehen. Dies ist kritisch für die im Spielplan definierten Test-Fenster A (2022-2023) und B (2024-2026).

| Symbol | Earliest M1 Bar | Real Ticks (Fenster A) | Real Ticks (Fenster B) | Fazit für Backtests |
|--------|-----------------|------------------------|------------------------|---------------------|
| Alle 10| 03.01.2023      | ❌ Nicht verfügbar       | ⚠️ Download erforderlich | **Fenster A (2022) fehlt.** |

### Kritische Erkenntnis (Warnung)
> [!WARNING]
> Der erste verfügbare M1-Bar für **sämtliche** US-Aktien auf diesem MetaQuotes-Demo Server ist der **03.01.2023**.
> Das bedeutet, dass **Fenster A (2022-2023)**, wie im Handoff erhofft, **nicht komplett gefahren werden kann**, da das gesamte Jahr 2022 physisch beim Broker fehlt. Die Daten beginnen erst Anfang 2023. Das Test-Design (In-Sample/Out-Of-Sample Fenster) für den Aktien-Korb muss dementsprechend auf den Zeitraum 2023-2026 angepasst werden.
