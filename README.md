# Trading-Bot: MQL5 Expert Advisor für MetaTrader 5

Ein Expert Advisor (EA) – ein Programm, das in MetaTrader 5 selbstständig
handelt. Er wird im **Strategy Tester** gebacktestet; ein Demo-Einsatz
(Spielgeld) kommt erst, wenn eine Strategie nachweislich robust ist.
Zielkonto: Forex, Hedged, EUR, 1.000 EUR Startkapital, Hebel 1:30.

**Ehrlicher Projektstand:** Wir sind in einer *Forschungsphase*. Nach
121 dokumentierten Backtests über 9 Strategie-Familien hat noch **keine**
getestete Signal-Idee einen instrumentübergreifend robusten,
statistisch belastbaren Vorteil gezeigt (Details: `backtests.csv`,
`KONTEXT.md`). Zuletzt fielen Cointegration-Pair-Trading (Backtest 14),
ein Saisonalitäts-/Session-Filter (Backtest 15) und ein Carry-Basket
(Backtest 16) durch – jeweils out-of-sample negativ. Ein MT5-News-Filter
wurde gebaut, ist aber im Strategy Tester nicht backtestbar (der Kalender
liefert dort keine Historie). Der EA selbst ist ein solides, generisches
Test-Gerüst – gesucht wird die Signal-Kante.

## Projektstruktur

```
experts/        MQL5-EAs (.mq5) – aktiv: ema_mtf_v3.mq5 (v3.51);
                Kandidaten: structure_swing_ea.mq5, pair_trading_v1.mq5,
                carry_basket_v1.mq5 (alle getestet, kein robuster Edge)
scripts/        Cointegration-Pre-Check (Script + EA-Variante) + Ergebnis
tools/          validate_backtests.py, pool_backtests.py, checklist_new_strategy.md
                pipeline/ (Backtest-Automatisierung: run_backtest.ps1 + parse_report.py)
backtests.csv   Register ALLER Backtests (Kennzahlen, z-Score, Hypothese, Fazit)
hypothesen.md   Hypothesen-Register (Mechanismus-vor-Test, Anti-HARKing)
KONTEXT.md      Aktueller Stand + Chronik + Roadmap (Handoff-Datei)
JOURNAL.md      Tagebuch mit Tageseintraegen
EA_CODE.md      Kompletter EA-Code als Markdown (Handoff)
docs/           REVIEW_VERBESSERUNG.md (Review/Roadmap, historisch)
CLAUDE.md       Projektregeln
```

## Der aktive EA: `experts/ema_mtf_v3.mq5`

Generisches Test-Gerüst mit allem per Eingabe-Parameter schaltbar:

- **Signal (Modus 0):** EMA-9/21-Kreuz auf der Chart-Zeitebene,
  Trend-Bias von einer höheren Zeitebene (z. B. H4/D1); Long und Short.
- **Signal (Modus 1):** RSI-Mean-Reversion (getestet, verworfen).
- **Risiko:** Stop unter/über dem letzten Swing-Punkt + ATR-Puffer;
  Positionsgröße so, dass ein Stop-Treffer genau 1 % vom Kapital kostet
  (seit v3.41 via `OrderCalcProfit`, korrekt auch für Nicht-Forex).
- **Ausstieg:** dynamischer TP (Risiko × Faktor), ATR-Trailing,
  optional Break-Even + Teil-Gewinnmitnahme.
- **Filter:** RSI, optional Volatilitätsfilter (ATR-D1 ≥ 100-Tage-Median).
- **Schutz:** Tagesverlust-Limit; `OnTester()` schreibt alle Kennzahlen
  für die automatische Auswertung.

## EA in MetaTrader 5 einrichten

1. In MT5: **Datei → Dateiordner öffnen** → `MQL5\Experts\` → die
   `.mq5` aus `experts/` dorthin kopieren.
2. MetaEditor (**F4**), Datei öffnen, **F7 kompilieren** → „0 errors".
3. Backtest: **Strg+R** (Strategy Tester) → EA wählen → Symbol/Zeitebene/
   Zeitraum einstellen → Start. (Backtests laufen in diesem Projekt
   normalerweise automatisiert; jeder Lauf wird in `backtests.csv`
   protokolliert.)
4. Demo-Paper-Trading (erst nach nachgewiesen robuster Strategie):
   EA auf den Chart ziehen, „Algo Trading" aktivieren.

## Test-Disziplin (die wichtigste Regel)

Jede neue Strategie-Idee wird geprüft mit:
1. **Out-of-Sample:** getrennte Fenster (A: 2022–2023, B: 2024–2026) –
   nicht nur ein durchgehender Zeitraum.
2. **Generalisierung:** Gegentest auf einem zweiten Instrument (GBPUSD).
3. **Statistik:** Ziel |z-Score| > 2 bei sauberem 1-%-Risiko –
   sonst ist ein Ergebnis vom Zufall nicht zu unterscheiden.

Live-Trading kommt frühestens nach bestandenen, dokumentierten Tests und
ist allein Entscheidung und Handlung des Nutzers.
