# Critical Review & Verbesserung – Trading-Bot-Projekt

> **Kontext:** Antwort auf den GLM-5.1-Vorschlag vom 13.07.2026 betreffend Pair-Trading-Erweiterung, Claude-Code-Prompt und Modell-Workflow.
> **Zweck:** Kritische Würdigung des GLM-5.1-Vorschlags, Behebung der technischen und konzeptionellen Blindstellen, erweiterter Claude-Code-Prompt, überarbeiteter Modell-Workflow, zusätzliche strategische Ideen.
> **Format:** Markdown, passend zu den Repo-Konventionen (`KONTEXT.md`, `JOURNAL.md`, `CLAUDE.md`).

---

## TL;DR — Die 7 kritischsten Blindstellen im GLM-5.1-Vorschlag

| # | Blindstelle | Konsequenz |
|---|---|---|
| 1 | **MT5 Strategy Tester liefert für das sekundäre Symbol degradierte Tick-Daten** | Pair-Trading-Backtest wird unrealistisch glatt; Ergebnisse möglicherweise wertlos |
| 2 | **EURUSD/GBPUSD sind korreliert (~0,8), aber NICHT cointegriert** | Pair-Trading-Idee vermutlich schon vor dem Coden tot (Brexit, BoE-vs-ECB-Divergenz) |
| 3 | **Python-Vorschlag für Cointegration-Test verstößt gegen `CLAUDE.md`** | "MQL5/MT5 ist der komplette Stack – kein Python (vorerst)" – Projekt wird unabsichtlich aufgebrochen |
| 4 | **MT5 Calendar API (`CalendarValueHistory`) übersehen** | News-Filter funktioniert OHNE externe Daten, im Tester – GLM 5.1 hat das kategorisch ausgeschlossen |
| 5 | **Transaktionskosten-Verdopplung bei Pair-Trading nicht thematisiert** | 2× Spread + 2× Kommission + Swap-Differential frisst marginalen Edge sofort |
| 6 | **`OnTester()`/`pool_backtests.py`-Integration im Prompt nicht erwähnt** | Claude Code baut neuen EA, der nicht ins bestehende Pooling-Rahmenwerk passt |
| 7 | **Look-Ahead-Bias in der Hedge-Ratio-Spezifikation nicht explizit ausgeschlossen** | "Letzte 100 Kerzen" inkl. aktueller Kerze = Look-Ahead; muß zwingend `iClose(..., 1)` statt `iClose(..., 0)` spezifizieren |

Zusätzlich **fünf übersehene strategische Ideen** (siehe Teil 4): MT5-Calendar-News-Filter, Tick-Volume-Profile, Carry-Trade-Basket, Volatility-Expansion (≠ ORB), Cross-Asset-Bestätigung via DXY.

---

## Teil 1: Kritische Würdigung der GLM-5.1-Analyse

### 1.1 Was richtig und stark war

- **Architektur-Diagnose korrekt:** Single-Symbol-Fokus des aktuellen EA ist tatsächlich der architektonische Flaschenhals für Pair-Trading. GLM 5.1 hat das als Einziger klar benannt.
- **Methodische Grundsätze erhalten:** Pooling, OOS-Fenster A/B, Z-Score-Grenze |z|>2, 1-%-Risiko – alles korrekt übernommen.
- **Cointegration-vs-Korrelation-Distinktion:** Daß bloße Korrelation für Pair-Trading nicht reicht, ist methodisch richtig angemerkt.
- **4-Stufen-Workflow** mit Rollenverteilung (Stratege, Coder, Reviewer, Dokumentator) ist didaktisch sauber.
- **Review-Checkliste** (Look-Ahead, Repainting, Syntax) für Claude Free ist ein guter Ansatz.

### 1.2 Was falsch, unvollständig oder gefährlich ist

#### 1.2.1 MT5 Strategy Tester – Multi-Symbol-Limitation (kritisch)

**Das Problem:** Der MT5 Strategy Tester lädt **volle Tick-Historie nur für das Symbol, das im Tester ausgewählt ist**. Alle anderen Symbole werden mit **niedrigerer Auflösung** geladen (typischerweise M1-Konstruktion, "Every tick based on real ticks" greift nur für das Haupt-Symbol). Bei Pair-Trading ist aber genau die **Tick-Präzision des sekundären Symbols entscheidend** für die Spread-Berechnung und die simultane Ausführung.

**Konsequenz für den Prompt:** Ein Pair-Trading-Backtest im MT5-Tester wird den Spread unrealistisch glätten, Slippage unterschätzen und die simultane Ausführung synthetisieren. Das ist **dieselbe Kritik, die GLM 5.1 an den MetaQuotes-Daten geübt hat** – nur wendet er sie nicht auf den eigenen Pair-Trading-Vorschlag an.

**Lösungsmöglichkeiten (alle haben Trade-offs):**
1. **Custom Symbol mit Dukascopy-Tick-Data** für das sekundäre Symbol (aufwendig, aber methodisch sauber – siehe Teil 5).
2. **Test-Modus "1 Minute OHLC"** bewusst wählen und dokumentieren, daß das eine obere Schranke für realistische Ergebnisse ist (keine Tick-Illusion).
3. **Walk-Forward-Demo-Test** nach Backtest – der Demo-Server liefert echte Ticks für beide Symbole.

**Empfehlung für den Prompt:** Explizit fordern, daß Claude Code im Code einen `MQLInfoInteger(MQL_TESTER)`-Zweig einbaut, der im Tester-Modus ein Log-Warning schreibt, wenn das sekundäre Symbol nicht der Haupt-Chart ist. Zusätzlich Test-Modus dokumentieren.

#### 1.2.2 EURUSD/GBPUSD – Cointegration-Realitätscheck (kritisch)

**Das Problem:** GLM 5.1 erwähnt Cointegration-Tests, übergeht aber die empirische Evidenz. EURUSD und GBPUSD weisen eine Korrelation von ~0,7–0,9 auf (je nach Fenster), sind aber **nicht im strengen Sinne cointegriert**:

- **Strukturbrüche:** Brexit-Referendum (Juni 2016), GBP-Absturz Oktober 2016 ("flash crash"), BoE-vs-ECB-Monatspolitik-Divergenz 2022–2024, Gilt-Krise September 2022.
- **Stochastic Trend:** Beide Währungen haben unterschiedliche fundamentale Treiber (GBP = UK-Zinsen + Handelsbilanz; EUR = EZB-Politik + Peripherie-Spreads). Die Log-Ratio EUR/GBP ist eher Random Walk mit Drift als mean-reverting.
- **Akademische Evidenz:** Studien zu FX-Pair-Trading (z.B. Krauss 2017, Do & Faff 2010) zeigen, daß statische Pair-Trading-Edges auf Majors seit ~2010 weitgehend verschwunden sind – HFT hat das arbitraged.

**Konsequenz:** Bevor Claude Code auch nur eine Zeile schreibt, sollte ein Cointegration-Test (ADF auf Residuen der Regression, Engle-Granger) über 2022–2026 laufen. Wenn der p-Wert > 0,05 ist, ist das Projekt mindestens auf diesem Paar tot.

**Lösung:** Siehe Teil 5 – Cointegration-Test **in MQL5** (nicht Python, siehe 1.2.3), oder als saubere Ausnahme in einem separaten Notebook außerhalb des Repos.

#### 1.2.3 Python-Vorschlag verstößt gegen `CLAUDE.md`

**Wortlaut aus `CLAUDE.md`:** *"MQL5/MT5 ist der komplette Stack – kein Pine Script, kein Python (vorerst; der frühere TradingView/Python-Stand liegt in der Git-Historie und kann jederzeit wiederhergestellt werden)."*

GLM 5.1 schlägt vor: *"Bevor du das in MQL5 baust, solltest du in Python prüfen, ob EURUSD/GBPUSD überhaupt cointegriert sind."*

**Das ist ein Disziplinbruch**, der drei Probleme erzeugt:
1. **Scope Creep:** Wenn einmal Python reinkommt, kommt es für alles rein (Datenanalyse, Visualisierung, Reporting).
2. **Doppelter Code:** Cointegration-Logik einmal in Python, einmal in MQL5 (für die Online-Berechnung der Hedge-Ratio im EA).
3. **Wartbarkeit:** Zwei Toolchains, zwei Abhängigkeits-Manager, zwei Fehlerquellen.

**Drei saubere Lösungswege:**

| Option | Beschreibung | Empfehlung |
|---|---|---|
| **A: MQL5-only** | Cointegration-Test als MQL5-Script (`scripts/cointegration_test.mq5`), Ausgabe als Print/CSV. Nutzt `MathCov`, `MathCorrelation`, manuelle ADF-Implementierung. | Methodisch konsequent, aber ADF in MQL5 ist Aufwand (~150 Zeilen). |
| **B: Explizite Ausnahme** | Einmaliger Python-Check im `/analysis/`-Ordner außerhalb des MQL5-Stacks, dokumentiert in `CLAUDE.md` als zeitlich begrenzte Ausnahme. | Pragmatisch, aber Gefahr der Ausweitung. |
| **C: Externes Notebook** | Jupyter-Notebook in einem separaten Repo/Ordner, nur für explorative Analyse, nicht Teil der Pipeline. | Sauberste Trennung, erfordert aber Disziplin. |

**Empfehlung:** Option A (MQL5-only) für die Cointegration-Logik, weil sie ohnehin im EA als rolling Berechnung gebraucht wird. Für einmalige explorative Plots Option C mit klarer Trennung.

#### 1.2.4 MT5 Calendar API übersehen

**Das Problem:** GLM 5.1 schreibt: *"News-/Kalender-Filter ... braucht einen Kalender-Feed = außerhalb des Testers."* **Das ist falsch.**

MT5 verfügt seit Build 2155+ über eine **eingebaute Wirtschaftsdaten-Kalender-API**:
- `CalendarValueHistory(symbol, from, to)` – alle Events für ein Symbol
- `CalendarEventById(event_id, event)` – Event-Details (Wichtigkeit, Land)
- `CalendarCountryById(country_id, country)` – Länder-Info

Die Kalenderdaten **stehen auch im Strategy Tester zur Verfügung** (für den Zeitraum der Backtests). Das macht News-Filterung **ohne externe Datenquelle** möglich.

**Konsequenz:** Der News-Filter ist eine der wenigen strategischen Ideen, die (a) im Tester testbar, (b) über alle Instrumente generalisierbar und (c) strukturell anders als alles bisherige ist. GLM 5.1 hat das fälschlicherweise ausgeschlossen.

**Empfehlung:** Siehe Teil 4.1 – eigener Prompt-Block für News-Filter-Erweiterung.

#### 1.2.5 Transaktionskosten-Verdopplung bei Pair-Trading

**Das Problem:** Pair-Trading öffnet **zwei Positionen gleichzeitig**. Das bedeutet:
- 2× Spread (je ~1,5 Pips EURUSD + GBPUSD = 3 Pips gesamt)
- 2× Kommission (falls erhoben, bei ECN-Konten ~3,5 USD pro Round-Turn pro Lot = 7 USD gesamt)
- 2× Slippage (im Tester schwer zu modellieren, aber real)
- Swap-Differential: Long EURUSD (-0,7 Pts/Tag) + Short GBPUSD (-1,0 Pts/Tag) = -1,7 Pts/Tag Gesamtkosten, Mittwoch 3×

**Rechnung bei typischem Trade (3 Tage gehalten, 1 Lot je Paar):**
- Spread-Kosten: ~30 USD
- Kommission: ~7 USD
- Swap: ~5 USD
- **Gesamt: ~42 USD pro Round-Turn**

**Vergleich zum erwarteten Edge:** Die `backtests.csv` zeigt, daß der beste positive Lauf (id31, VolFilter) einen Ø-Gewinn von ~158 EUR/Trade hat – aber das ist EIN Symbol, nicht zwei. Bei Pair-Trading ist der erwartete Profit pro Spread-Trade eher 20–80 EUR (weil der Spread-Rückgang klein ist). **Die Transaktionskosten können den Edge vollständig aufzehren.**

**Konsequenz für den Prompt:** Der Pair-Trading-Prompt muß explizit fordern:
- Berechnung der **erwarteten Round-Turn-Kosten** vor der Signalgenerierung
- Einstieg nur, wenn `|Spread-Z-Score| × Spread-Volatilität > 2 × Round-Turn-Kosten` (Sicherheitsabschlag)
- Reporting der Kosten-spezifischen Trefferquote in `OnTester()`

#### 1.2.6 `OnTester()` / `pool_backtests.py`-Integration fehlt

**Das Problem:** Der bestehende EA (`ema_mtf_v3.mq5`) hat eine etablierte `OnTester()`-Infrastruktur, die Kennzahlen nach `Common\Files\tester_result.txt` schreibt. Das `tools/pool_backtests.py`-Script poolt diese Ergebnisse über den 6er-Korb.

GLM 5.1 schreibt: *"Nutze den bestehenden Risk- und OnTester-Code aus `ema_mtf_v3.mq5` als Basis"* – das ist vage. Claude Code könnte einen neuen EA mit abweichendem `OnTester()`-Format bauen, das `pool_backtests.py` dann nicht mehr parsen kann.

**Konsequenz für den Prompt:** Explizit fordern:
- Identisches `OnTester()`-Output-Format wie `ema_mtf_v3.mq5` (dieselben Spalten, dieselbe Reihenfolge)
- Schema-Erweiterung nur über **neue Spalten am Ende**, nicht über Umbenennung
- Kompatibilitätstest: `tools/pool_backtests.py` muß ohne Anpassung laufen
- Neue Spalte `pair_id` (z.B. "EURUSD_GBPUSD") für die Paar-Identifikation

#### 1.2.7 Look-Ahead-Bias in der Hedge-Ratio-Spezifikation

**Das Problem:** GLM 5.1 spezifiziert: *"HedgeRatio rollierend berechnen (z.B. über lineare Regression der letzten 100 Kerzen)."* Das ist mehrdeutig:

- Variante A (falsch): Regression über Kerzen `[0..99]` inklusive aktueller Kerze 0 → **Look-Ahead-Bias**, weil die aktuelle Kerze zum Zeitpunkt der Signalgenerierung noch nicht geschlossen ist.
- Variante B (richtig): Regression über Kerzen `[1..100]` exklusive aktueller Kerze → korrekt, aber muß explizit spezifiziert werden.

**Konsequenz:** Look-Ahead-Bias ist der häufigste Fehler in Pair-Trading-Backtests und kann scheinbare Edges von PF 1,5+ erzeugen, die in Live-Demo sofort kollabieren.

**Lösung für den Prompt:** Explizite Spezifikation:
```mql5
// FALSCH (Look-Ahead):
double hedge = RegressionLSE(iClose(A, 0, 0), iClose(B, 0, 0), 100);
// RICHTIG:
double hedge = RegressionLSE(iClose(A, 0, 1), iClose(B, 0, 1), 100);
```
Zusätzlich: Hedge-Ratio muß **vor** der Spread-Berechnung aktualisiert werden, nicht danach.

#### 1.2.8 Symbol-Suffix-Handling fehlt

**Das Problem:** Live-Broker verwenden Suffixe: `EURUSD.m`, `EURUSD.raw`, `EURUSD.ecn`, `EURUSDpro`. Der aktuelle EA hat dieses Problem nicht, weil er nur ein Symbol kennt (`_Symbol`). Ein Multi-Symbol-EA braucht:
- Eingabeparameter `InpSymbolA` und `InpSymbolB` als Strings (mit Suffix)
- Validierung beim `OnInit()`: `SymbolSelect(InpSymbolA, true)` erzwingt, daß das Symbol im Market Watch ist
- Fallback: `SymbolInfoString(InpSymbolA, SYMBOL_SYMBOL)` liefert den kanonischen Namen

**Konsequenz für den Prompt:** Explizit fordern, daß `InpSymbolA`/`InpSymbolB` als Input-Parameter deklariert werden, mit `SymbolSelect()`-Aufruf in `OnInit()` und Fehler-Return falls Symbol nicht verfügbar.

#### 1.2.9 Z-Score-Threshold > 2,0 ist für FX-Spreads möglicherweise zu eng

**Das Problem:** FX-Spreads zwischen Majors haben typischerweise Kurtosis > 5 (fat tails) und niedrige Volatilität. Ein Z-Score > 2,0 tritt selten auf, und wenn, dann oft wegen eines fundamentalen Bruchs (NFP, Zinsentscheid), auf den keine Mean-Reversion folgt.

**Empirische Erfahrung aus Pair-Trading-Literatur:** Realistische Thresholds für FX-Pair-Trading liegen bei |Z| ≥ 1,5 bis 2,5, mit ** dynamischer Anpassung an die Kurtosis**. Statisch 2,0 ist eine Default-Annahme, die selten optimal ist.

**Lösung für den Prompt:** Threshold als Input-Parameter mit Default 2,0, aber **A-priori-Definition mehrerer Thresholds** (1,5 / 2,0 / 2,5), die in drei separaten Läufen getestet werden – NICHT optimiert, sondern vorab festgelegt als Multiple-Hypothesis-Test.

#### 1.2.10 Workflow-Schwäche: Kein Quality-Gate zwischen Stufen

**Das Problem:** Der 4-Stufen-Workflow von GLM 5.1 ist linear (Stratege → Coder → Reviewer → Dokumentator), aber ohne Quality-Gates. Wenn der Coder einen Fehler macht, den der Reviewer übersieht, geht der Fehler in die nächste Iteration.

**Lösung:** Explizite Quality-Gates:
- **Gate 1 (nach Stratege):** Hypothese muß in 3 Sätzen formulierbar sein, sonst abbrechen
- **Gate 2 (nach Coder):** Code muß kompilieren (0 Errors, 0 Warnings)
- **Gate 3 (nach Reviewer):** Alle gefundenen Fehler müssen als "fixed" markiert sein, mit Diff
- **Gate 4 (nach Backtest):** `validate_backtests.py` muß ohne Fehler durchlaufen

Diese Gates sind einfach, aber sie strukturieren den Workflow entscheidend.

---

## Teil 2: Verbesserter Prompt für Claude Code

Der folgende Prompt ist **direkt copy-paste-fähig** und ersetzt den GLM-5.1-Vorschlag. Er ist in drei Phasen gegliedert, die **sequentiell** abgearbeitet werden sollen (nicht parallel).

```markdown
# Auftrag für Claude Code – Pair-Trading-EA + Daten-Infrastruktur + News-Filter

## Ausgangslage (unbedingt vorab lesen!)
- Lies `KONTEXT.md`, `backtests.csv`, `EA_CODE.md`, `JOURNAL.md` vollständig.
- 61 Backtests, 6 Strategie-Familien, KEIN instrumentübergreifend robuster Edge.
- Pooling-Methodik funktioniert (N~500 pro Fenster, statistisch saubere Verwerfung).
- Nächster Schritt laut Projektplan: Mean-Reversion zwischen korrelierten Paaren.
- **NEU (nicht im ursprünglichen Plan):** News-Filter via MT5 Calendar API,
  weil dieser ohne externe Daten im Tester testbar ist.

## Eiserne Regeln (verstärkt gegenüber bisher)
1. Kein Python im Repo. Cointegration-Tests und alle Auswertungen in MQL5.
2. Kein Look-Ahead-Bias: Hedge-Ratio berechnet aus `iClose(..., 1)`, NIEMALS `iClose(..., 0)`.
3. Transaktionskosten-Modellierung: Round-Turn-Kosten = 2 × Spread + 2 × Kommission
   + Swap-Differential × Haltedauer. Vor Signalgenerierung prüfen.
4. `OnTester()`-Output-Format identisch zu `ema_mtf_v3.mq5`, neue Spalten nur anhängen.
5. `tools/pool_backtests.py` muß ohne Anpassung mit neuen Backtests funktionieren.
6. Kein Martingale, kein Grid, kein Nachkaufen in Verluste.
7. Vor jeder Code-Änderung: kurzer Plan im Chat. Keine Überraschungen.
8. MQL5-Code standardnah, kompiliert auf Anhieb (0 Errors, 0 Warnings).
9. Deutsche Kommentare, in .mq5 ohne Umlaute (ae/oe/ue/ss).
10. Keine Zugangsdaten in Code, Chat, Commits.

## Phase 1 – Cointegration-Pre-Check (VOR dem EA-Bau!)

**Ziel:** Bevor wir den Pair-Trading-EA bauen, prüfen wir, ob die Paare überhaupt
cointegriert sind. Wenn nicht, sparen wir uns den EA-Bau komplett.

**Neue Datei:** `scripts/cointegration_check.mq5` (Script, kein EA)

**Logik:**
1. Eingabeparameter: `InpSymbolA` (Default "EURUSD"), `InpSymbolB` (Default "GBPUSD"),
   `InpTimeframe` (Default PERIOD_H1), `InpLookback` (Default 2000, ~83 Tage H1).
2. Lade Schlusskurse beider Symbole aus `iClose(InpSymbolA, InpTimeframe, i)` für
   `i = 1..InpLookback` (WICHTIG: ab i=1, nicht i=0, um Look-Ahead zu vermeiden).
3. Berechne Hedge-Ratio via Least-Squares-Regression: beta = Cov(A,B) / Var(B).
4. Berechne Spread = Log(A) - beta × Log(B).
5. Führe **ADF-Test (Augmented Dickey-Fuller)** auf dem Spread durch:
   - Lag-Order nach Schwarz-Information-Criterion wählen (Default Lag=1).
   - Teststatistik t = (rho_hat - 1) / SE(rho_hat) aus der Regression
     Delta_Spread_t = alpha + rho × Spread_{t-1} + sum(phi_i × Delta_Spread_{t-i}) + e_t.
   - Kritische Werte (MacKinnon 1991, 1%/5%/10%): -3,43 / -2,86 / -2,57.
6. Ausgabe via `Print()` im Format:
   ```
   COINTEGRATION_RESULT;symbolA;symbolB;tf;lookback;beta;adf_t;critical_1pct;critical_5pct;critical_10pct;p_value_approx;verdict
   ```
   verdict = "COINTEGRATED" falls adf_t < critical_5pct, sonst "NOT_COINTEGRATED".
7. Speichere das Ergebnis zusätzlich in `Common\Files\cointegration_result.txt`.

**Test-Plan (VOR dem EA-Bau ausführen!):**
- Teste alle 6 Paar-Kombinationen aus dem 6er-Korb (EURUSD, GBPUSD, USDJPY, AUDUSD,
  USDCAD, XAUUSD): 15 Kombinationen.
- Zeitraum: 2022-01-01 bis 2026-07-11 (volle Historie).
- **Abbruch-Kriterium für Phase 2:**
  - Wenn KEINE Kombination cointegriert ist → Phase 2 überspringen, direkt zu Phase 3.
  - Wenn 1–3 Kombinationen cointegriert sind → nur diese für Phase 2 verwenden.
  - Wenn >3 cointegriert sind → die 3 mit der niedrigsten p-Value auswählen.

**Output an `KONTEXT.md`:** Neue Sektion "## Cointegration-Pre-Check (Phase 1)"
mit Tabelle aller 15 Kombinationen, Verdict und Entscheidung.

---

## Phase 2 – Multi-Symbol Pair-Trading-EA (nur wenn Phase 1 cointegrierte Paare liefert!)

**Neue Datei:** `experts/pair_trading_v1.mq5`

### Architektur (Pflicht-Vorgaben)

1. **Multi-Symbol-Setup:**
   - Input-Parameter: `InpSymbolA` (Default "EURUSD"), `InpSymbolB` (Default "GBPUSD").
   - Im `OnInit()`: `SymbolSelect(InpSymbolA, true)` und `SymbolSelect(InpSymbolB, true)`
     erzwingen. Fehler-Return `INIT_FAILED` falls Symbol nicht verfügbar.
   - Suffix-Handling: Nutze `SymbolInfoString(symbol, SYMBOL_SYMBOL)` für kanonischen Namen
     in Logs, aber handle mit dem Input-String für Orders.

2. **Hedge-Ratio-Berechnung (Look-Ahead-frei!):**
   ```mql5
   // Nutze geschlossene Kerzen ab Index 1, NIEMALS Index 0
   double GetHedgeRatio(string symA, string symB, ENUM_TIMEFRAMES tf, int lookback) {
       // 1. Sammle iClose(symA, tf, i) und iClose(symB, tf, i) fuer i = 1..lookback
       // 2. Berechne Cov(A,B) und Var(B) via ein-Pass-Algorithmus
       // 3. Return Cov(A,B) / Var(B)
   }
   ```

3. **Spread- und Z-Score-Berechnung:**
   - Spread = Log(Close_A) - HedgeRatio × Log(Close_B), auf der letzten geschlossenen Kerze.
   - Rollierender Mean und Std des Spreads über `InpSpreadLookback` (Default 100) Kerzen,
     wieder ab Index 1 (Look-Ahead-frei!).
   - Z-Score = (Spread - Mean) / Std.

4. **Einstiegslogik (A-priori festgelegt, NICHT optimieren!):**
   - Long Spread (Long A, Short B): Z-Score < -InpZEntry (Default 2,0).
   - Short Spread (Short A, Long B): Z-Score > +InpZEntry.
   - **Transaktionskosten-Check vor Einstieg:**
     ```
     double round_turn_cost = 2 * (Spread_A + Spread_B) * tick_value
                            + 2 * commission_per_lot
                            + swap_diff * expected_hold_bars;
     double expected_profit = fabs(Z-Score - 0) * spread_std_dev * lot_value;
     if (expected_profit < 2 * round_turn_cost) REJECT_SIGNAL;
     ```
   - Maximal 1 gleichzeitige Spread-Position pro Paar (keine Pyramiding).

5. **Ausstiegslogik:**
   - Take-Profit: Z-Score kehrt zu 0 zurück (auf die entgegengesetzte Seite oder === 0).
   - Hard Stop: |Z-Score| > InpZStop (Default 3,5).
   - Time-Stop: max `InpMaxHoldBars` (Default 200, ~8 Tage H1).
   - Trailing: Z-Score-basiert, zieht nach wenn Z-Score sich 50% zurückbewegt hat.

6. **Positionsgröße (Market-Neutral in Kontowährung):**
   - Berechne Lot_A so, daß |Stop_A| in Kontowährung genau InpRiskPerTradePct/2 (0,5%) beträgt.
   - Berechne Lot_B so, daß |Stop_B| in Kontowährung ebenfalls 0,5% beträgt
     (NICHT HedgeRatio-gewichtet – das wäre Dollar-Neutral, aber nicht Risk-Neutral;
     für FX-Pair-Trading ist Risk-Neutral die sicherere Wahl, weil die Stop-Distanzen
     unterschiedlich sind).
   - Verwende `OrderCalcProfit` (nicht `tick_value`, siehe v3.41-Lektion!).

7. **OnTester()-Integration (Zwingend kompatibel zu ema_mtf_v3.mq5!):**
   - Identische Spalten wie `backtests.csv`, in derselben Reihenfolge.
   - NEUE Spalten am Ende (nicht umbenennen!):
     - `pair_id`: String "EURUSD_GBPUSD"
     - `hedge_ratio`: finaler Hedge-Ratio-Wert
     - `avg_z_at_entry`: Ø Z-Score bei Einstieg
     - `avg_hold_bars`: Ø Haltedauer in Bars
     - `round_turn_cost_eur`: Ø Round-Turn-Kosten pro Trade in EUR
   - Schreibe nach `Common\Files\tester_result.txt` im selben Format wie `ema_mtf_v3.mq5`.
   - `tools/pool_backtests.py` muß ohne Anpassung funktionieren.

8. **Tester-Modus-Hinweis (kritisch!):**
   - Schreibe im `OnInit()` einen Log-Eintrag:
     ```
     Print("WARNING: MT5 Strategy Tester liefert nur fuer das Haupt-Symbol volle
     Tick-Daten. Sekundaer-Symbol hat degraded ticks. Pair-Trading-Ergebnisse
     sind eine OBere Schranke, keine realistische Simulation.");
     ```
   - Im `OnTester()` zusätzlich: schreibe `test_mode` in die Ergebnisdatei
     ("every_tick" / "1min_ohlc" / "open_prices").

### Test-Plan (A-priori festgelegt, NICHT optimieren!)

- **Paare:** Nur die cointegrierten aus Phase 1 (maximal 3).
- **Zeitebene:** H1 (Chart), H4 (Bias – falls Bias überhaupt nötig ist; eigentlich
  ist der Spread-Biasfrei).
- **Zeiträume:** Fenster A (2022-01-01 bis 2023-12-31), Fenster B (2024-01-01 bis 2026-07-11).
- **Thresholds:** Drei separate Läufe pro Paar mit `InpZEntry` = 1,5 / 2,0 / 2,5
  (Multiple-Hypothesis-Test, kein Optimieren!).
- **Pooling:** Über alle cointegrierten Paare, separater Report pro Threshold.
- **Erfolgskriterium:** Gepoolt |z| > 2,0 UND PF > 1,0 in BEIDEN Fenstern UND
  `round_turn_cost_eur` < 50% des Ø-Gewinns der Gewinner-Trades.
- **Abbruch-Kriterium:** Gepoolt PF < 0,95 in einem der Fenster ODER |z| < 1,0
  → Idee verworfen, keine Parameteroptimierung.

### Output an `KONTEXT.md` und `JOURNAL.md`
- Neue Sektion "## Pair-Trading-Backtest (Phase 2)" mit Tabelle.
- JOURNAL-Eintrag mit Datum, was gemacht wurde, was herauskam, was entschieden wurde.
- `backtests.csv`: Eine Zeile pro Lauf, identisches Schema + neue Spalten.

---

## Phase 3 – Datenquellen-Erweiterung & News-Filter (parallel zu Phase 2 planbar)

Falls Phase 2 scheitert (wahrscheinlich) oder ergänzend, diese drei Erweiterungen
des Haupt-EAs `ema_mtf_v3.mq5`. **Jede als separater Toggle, isoliert testen!**

### 3.1 – MT5 Calendar API News-Filter (NEU, nicht in GLM-5.1-Plan!)

**Hypothese:** Hohe Volatilität um Wirtschaftsdaten (NFP, Zinsentscheide, CPI) ist
unberechenbar. Filterung dieser Zeiten sollte die Trefferquote erhöhen.

**Logik:**
1. Neuer Input `InpUseNewsFilter` (Default false).
2. Neuer Input `InpNewsBlockMinutesBefore` (Default 30) und `InpNewsBlockMinutesAfter` (Default 30).
3. Neuer Input `InpNewsImportance` (Default HIGH = 3, Medium = 2, Low = 1).
4. Vor jedem Einstieg: rufe `CalendarValueHistory(_Symbol, time_current() - 3600, time_current() + 3600)` auf.
5. Falls ein Event mit Wichtigkeit >= `InpNewsImportance` innerhalb der Block-Window liegt → Einstieg ablehnen.
6. Verwende `CalendarEventById` und `CalendarCountryById`, um Land zu prüfen
   (nur Events für USD bei EURUSD, für GBP bei GBPUSD, etc.).

**Achtung:** Im Strategy Tester müssen die Kalenderdaten verfügbar sein.
Vorab-Check in `OnInit()`:
```mql5
MqlCalendarValue values[];
int count = CalendarValueHistory(_Symbol, D'2022-01-01', D'2022-01-02', values);
if (count == 0) Print("WARNING: Calendar-Daten im Tester nicht verfuegbar.");
```

**Test-Plan:** Sechs-Korb, Fenster A/B, mit vs ohne Filter. Gepoolt |z| vergleichen.

### 3.2 – Saisonalitäts-Filter (Stunde/Wochentag)

**Hypothese:** FX hat saisonale Muster (Asien-Session lower volatility für EURUSD,
London-Fix-Spike 16:00 London, NY-Open 13:30 EET).

**Logik:**
- Neuer Input `InpTradingHoursStart` / `InpTradingHoursEnd` (Default 8 / 20 EET).
- Neuer Input `InpTradingDaysMask` (Bitmask: bit0=Mo ... bit4=Fr; Default 0b11111 = Mo-Fr).
- Isoliert testen: welche Stunden weglassen erhöht PF? (Multiple-Hypothesis-Test über
  4-Stunden-Blöcke: 0-4, 4-8, 8-12, 12-16, 16-20, 20-24 EET.)

### 3.3 – Korb-Volatilitätsregime

**Hypothese:** Bei niedrigem ATR-Korb-Niveau sind Breakouts/EMA-Signale sinnlos
(Markt tot, Range-Dominanz).

**Logik:**
- Berechne ATR-D1 für alle 6 Korb-Symbole via `iATR`.
- Berechne Durchschnitts-ATR normalisiert (ATR/Price × 100).
- Vergleiche mit rollierendem 100-Tage-Median.
- Toggle: kein Trading wenn Korb-ATR < 0,8 × Median.

### 3.4 – Carry-Trade-Signal (zusätzlich, war in GLM-5.1 nur skizziert)

**Hypothese:** Positiver Swap = Carry-Trade-Edge, negativer Swap = Anti-Carry.

**Logik:**
- Lese `SymbolInfoInteger(sym, SYMBOL_SWAP_LONG)` und `SYMBOL_SWAP_SHORT` für alle 6 Symbole.
- Berechne Carry-Score = swap_long - swap_short (punkte/Tag).
- Kaufe nur Top-2-Carry-Symbole, verkaufe Bottom-2-Anti-Carry.
- Halte 5 Tage, rolle nicht (isolierter Test).

---

## Vorgaben für alle Phasen
- Vor jeder Code-Änderung: Plan im Chat, kein Auto-Commit.
- MQL5-Code muß auf Anhieb kompilieren (0 Errors, 0 Warnings).
- Jeder Backtest-Lauf wird in `backtests.csv` protokolliert (eine Zeile, identisches
  Schema, neue Spalten am Ende für Phase 2).
- `tools/validate_backtests.py` muß nach jedem neuen Eintrag ohne Fehler durchlaufen.
- `KONTEXT.md` und `JOURNAL.md` am Ende jeder Sitzung aktualisieren und committen.
- Keine Zugangsdaten im Code, Chat oder Commits.
- Kommentare Deutsch, in .mq5 ohne Umlaute.

## Reihenfolge (verbindlich)
1. **Phase 1 zuerst:** Cointegration-Pre-Check. Ergebnis in `KONTEXT.md` dokumentieren.
2. **Dann Entscheidung:** Phase 2 nur, wenn cointegrierte Paare existieren.
3. **Phase 3 parallel:** News-Filter und Saisonalität können unabhängig entwickelt werden.
4. **Pro Sitzung:** Nur EINE Phase bearbeiten, sauber committen, dann nächste.
```

---

## Teil 3: Verbesserter Workflow für alle Modelle

GLM 5.1 hat den Workflow linear entworfen (Stratege → Coder → Reviewer → Dokumentator). Das ist didaktisch sauber, aber **ohne Quality-Gates** und **ohne parallele Pipelines**. Hier ist der überarbeitete Workflow mit expliziten Gates und parallelen Pfaden, optimiert auf die verfügbaren 5 Modelle (GLM 5.1, Claude Pro / Claude Code, 3× Claude Free).

### 3.1 Rollen-Matrix (überarbeitet)

| Rolle | Modell | Warum dieses Modell? | Hauptverantwortung |
|---|---|---|---|
| **Stratege & Quant** | GLM 5.1 (dieser Chat) | Stark in quantitativer Logik, kritischer Konzeptanalyse | Hypothesen formulieren, Mathematik prüfen, Edge-Plausibilität bewerten |
| **Architekt & Coder** | Claude Pro / Claude Code | Direkter Repo-Zugriff, MQL5-Expertise | Code schreiben, kompilieren, Backtests automatisieren, Git-Commits |
| **Code-Reviewer 1 (Look-Ahead)** | Claude Free #1 | Kontingente schonen, fokussierte Aufgabe | Look-Ahead-Bias, Repainting, Syntax-Fehler prüfen |
| **Code-Reviewer 2 (Statistik)** | Claude Free #2 | Kontingente schonen, andere Perspektive | Statistische Validität, Sample-Size, Multiple-Testing-Korrektur prüfen |
| **Dokumentator & Daten-Analyst** | Claude Free #3 | Routine-Aufgaben, Formatierung | `backtests.csv`-Einträge, `JOURNAL.md`-Einträge, `KONTEXT.md`-Updates |

### 3.2 Quality-Gates zwischen Stufen

**Gate 1 (nach Stratege, vor Coder):**
- Hypothese in ≤ 3 Sätzen formuliert? → sonst zurück an Stratege
- A-priori-Parameter festgelegt (nicht optimieren)? → sonst zurück
- Test-Plan mit Fenster A/B und ≥1 Zweitinstrument definiert? → sonst zurück
- Abbruch-Kriterium numerisch festgelegt? → sonst zurück

**Gate 2 (nach Coder, vor Reviewer):**
- Code kompiliert mit 0 Errors UND 0 Warnings? → sonst zurück
- `OnTester()`-Output-Format identisch zu `ema_mtf_v3.mq5`? → sonst zurück
- Input-Parameter alle dokumentiert (Default, Range, Begründung)? → sonst zurück

**Gate 3 (nach Reviewer, vor Backtest):**
- Alle Look-Ahead-Fehler als "fixed" markiert mit Diff? → sonst zurück
- Reviewer-Checkliste vollständig abgehakt? → sonst zurück

**Gate 4 (nach Backtest, vor Dokumentator):**
- `tools/validate_backtests.py` läuft ohne Fehler? → sonst zurück
- `risk_realized_pct` im Bereich 0,8–1,2% (Sizing korrekt)? → sonst zurück
- `trades` ≥ 50 pro Fenster (statistische Aussagekraft)? → sonst kennzeichnen

### 3.3 Konkrete Prompts je Modell

#### Stufe 1 – Stratege (GLM 5.1, dieser Chat)

**Setup:** Kopiere `KONTEXT.md`, `backtests.csv`, `EA_CODE.md` und die letzte `JOURNAL.md`-Sektion in den Chat.

```
Du bist mein Quant-Stratege. Pflichtlektüre steht oben (KONTEXT.md, backtests.csv,
EA_CODE.md, JOURNAL.md). Lies zuerst backtests.csv, dann KONTEXT.md.

Deine Rolle: Hypothesen formulieren, Mathematik prüfen, Edge-Plausibilität bewerten.
Du schreibst KEINEN Code (das macht Claude Code).

Eiserne Regeln:
1. Kein Martingale/Grid/Nachkaufen in Verluste.
2. Erwartung > Trefferquote (91% Winrate mit Minus belegt).
3. Keine Zugangsdaten.
4. Backtest → Demo → Live (nur durch Nutzer).
5. Robuster Edge = PF ~1,1, nicht "10%/Monat".

Was wir gelernt haben (nicht wiederholen):
- KEINE getestete Konfig hat OOS-robusten Edge (|z|>2).
- EURUSD-spezifische Gewinne (VolFilter) generalisieren NICHT auf GBPUSD.
- M15/M30 verlieren, ORB signifikant negativ (z=-2,61 gepoolt).
- Struktur-Swing = Rauschen.
- Multiple-Testing-Problem nach 37+ Tests: einzelne gute Fenster sind Zufall.

Workflow:
1. Lies KONTEXT.md + backtests.csv.
2. Schlage EINE Hypothese vor (Format unten).
3. Ich reiche an Claude Code weiter, der backtestet.
4. Ich bringe Ergebnis zurück, du bewertest und schlägst nächste Hypothese vor.

Format für Hypothese:
- HYPOTHESE: <was und warum, 1-2 Sätze>
- AENDERUNG: <welcher Code/Parameter, isoliert>
- TESTPLAN: <Symbol, TF, Zeitraum, Fenster>
- ERFOLG: <was wäre Erfolg, numerisch>
- ABBRUCH: <was wäre Misserfolg, numerisch>
- A_PRIORI_PARAMETER: <alle Werte vorab festgelegt, kein Optimieren>

Beginne: Fasse aktuellen Stand in 3 Sätzen zusammen, schlage dann EINE Hypothese vor.
```

#### Stufe 2 – Architekt & Coder (Claude Pro / Claude Code)

**Setup:** Wirf den Prompt aus **Teil 2** dieser Datei in Claude Code. Claude Code hat Repo-Zugriff.

**Wichtiger Handgriff:** Bevor du den Prompt abschickst, stelle sicher, daß `KONTEXT.md`, `backtests.csv`, `EA_CODE.md` auf dem neuesten Stand sind (Commit vorher).

**Nach der Code-Generierung:** Claude Code muß folgende Checkliste selbst abhaken (in den Commit-Message schreiben):
```
[ ] Code kompiliert mit 0 Errors, 0 Warnings
[ ] OnTester() Output-Format identisch zu ema_mtf_v3.mq5
[ ] Look-Ahead-Bias ausgeschlossen (iClose mit Index 1, nicht 0)
[ ] SymbolSelect() im OnInit() implementiert
[ ] Keine Umlaute in .mq5-Datei
[ ] backtests.csv aktualisiert mit neuer Zeile
[ ] tools/validate_backtests.py läuft ohne Fehler
[ ] KONTEXT.md und JOURNAL.md aktualisiert
```

#### Stufe 3a – Code-Reviewer 1: Look-Ahead & Repainting (Claude Free #1)

**Setup:** Kopiere den generierten `.mq5`-Code in ein frisches Claude-Free-Gespräch.

```
Du bist ein strenger Code-Reviewer für MQL5-Code. Prüfe den folgenden Code auf
drei Fehlerklassen:

1. LOOK-AHEAD-BIAS:
   - Werden iClose/iHigh/iLow/iOpen mit Shift 0 verwendet, wo Shift 1 nötig wäre?
   - Werden Indikator-Puffer (iATR, iMA, etc.) auf der aktuellen Kerze gelesen,
     bevor die Kerze geschlossen ist?
   - Wird die Hedge-Ratio / Regression inklusive der aktuellen Kerze berechnet?
   - Werden Orders platziert mit time_current() als Referenz, wo time[0] nötig wäre?

2. REPAINTING:
   - Verschieben sich Indikator-Werte alter Kerzen, wenn neue Kerzen dazukommen?
   - Wird in OnCalculate() oder OnInit() Puffer zurückgeschrieben?
   - Werden Swing-Punkte oder Fractals nachträglich verschoben?

3. SYNTAX-FEHLER MIT LOGISCHER AUSWIRKUNG:
   - Vergleiche mit = statt == in if-Bedingungen?
   - Integer-Division wo Float nötig?
   - Type-Casts, die still Werte verändern?
   - Off-by-One in Schleifen (i < vs i <=)?

Antworte AUSSCHLIESSLICH mit:
- Liste der gefundenen Fehler (mit Zeilennummer und Code-Snippet)
- Korrekturvorschlag (mit Diff-Format)
- Falls kein Fehler gefunden: "KEINE FEHLER GEFUNDEN" + kurze Bestätigung pro
  Fehlerklasse, daß geprüft wurde

Keine Erklärungen, kein Lob, keine Zusammenfassung. Nur Fehler oder Bestätigung.

CODE:
[einfügen]
```

#### Stufe 3b – Code-Reviewer 2: Statistische Validität (Claude Free #2, parallel zu 3a)

```
Du bist ein Statistiker und quantitativer Code-Reviewer. Prüfe den folgenden
MQL5-Code auf statistische Validität:

1. SAMPLE-SIZE:
   - Sind genug Trades zu erwarten (>= 50 pro Fenster fuer |z| >= 2)?
   - Werden Trades gepoolt oder einzeln ausgewertet?

2. MULTIPLE-TESTING:
   - Werden mehrere Thresholds/Parameter in denselben Fenstern getestet?
   - Falls ja: ist eine Bonferroni- oder FDR-Korrektur angewendet?

3. P-VALUE / Z-SCORE-BERECHNUNG:
   - Ist die Formel fuer z_score korrekt (Erwartung/SE)?
   - Wird die Standardabweichung ueber die richtigen Trades berechnet?
   - Sind die Freiheitsgrade korrekt (N-1)?

4. OVERLAP-ZEITRAEUME:
   - Ueberlappen sich Trainings- und Testfenster?
   - Werden "Gesamt"-Laufe als zusaetzliche Evidenz gezaehlt (verboten!)?

5. SURVIVORSHIP-BIAS / SELECTION-BIAS:
   - Werden nur profitable Instrumente nachtraeglich ausgewaehlt?
   - Sind die getesteten Symbole a priori festgelegt?

Antworte AUSSCHLIESSLICH mit:
- Liste der gefundenen Probleme (mit Code-Zeile und mathematischer Begruendung)
- Konkreter Korrekturvorschlag
- Falls kein Problem: "STATISTISCH VALIDE" + Bestaetigung pro Punkt

Keine Erklärungen, kein Lob. Nur Probleme oder Bestaetigung.

CODE:
[einfügen]
```

#### Stufe 4 – Dokumentator & Daten-Analyst (Claude Free #3)

**Setup:** Nachdem die Backtests im MT5 gelaufen sind, kopiere die rohen Ergebnisse (CSV oder Tester-Output) in Claude Free #3.

```
Du bist mein Trading-Daten-Analyst und Dokumentator. Hier sind die rohen Backtest-
Ergebnisse. Deine Aufgabe:

1. BERCHNE fuer jedes Fenster (A, B) und jeden Test-Run:
   - Gepoolter Profit Factor (Summe Gewinne / |Summe Verluste|)
   - Durchschnittlicher Z-Score (Erwartung / SE der Erwartung)
   - Ø Trades pro Symbol
   - Ø Hold-Time in Bars
   - Worst Drawdown

2. FORMATIERE als neue Zeile fuer backtests.csv (Schema siehe unten).
   Trennzeichen: Semikolon. Dezimaltrennzeichen: Punkt.
   Falls ein Wert nicht verfuegbar: leeres Feld (nicht "NaN" oder "null").

3. SCHREIBE einen JOURNAL.md-Eintrag fuer heute im Stil von:
   - "## YYYY-MM-DD (Tag N) – [Kurztitel]"
   - **Kurzfassung:** 2-3 Saetze
   - Bulletpoints mit: was gemacht, was herausgekommen, was entschieden, was offen
   - **Entscheidungen:** ...
   - **Offen:** ...
   Stil: nuechternes Trading-Tagebuch, keine Emotionen, keine Superlative.

4. SCHREIBE einen KONTEXT.md-Update-Block im Format:
   - "### Backtest N – [Strategie-Name] ([Datum])"
   - Tabelle mit Vergleich Vorher/Nachher
   - Fazit: Edge vorhanden? Generalisiert? Naechster Schritt?

SCHEMA backtests.csv:
id;datum;ea_version;zeitraum;symbol;exec_tf;bias_tf;richtung;strategie;net_profit;
profit_factor;sharpe;dd_pct;trades;win_rate_pct;avg_win;avg_loss;max_loss_streak;
risk_realized_pct;z_score;fazit

Antworte mit:
- CSV-Zeile(n) in Code-Block
- JOURNAL-Eintrag in Code-Block
- KONTEXT-Update in Code-Block
- Kein weiterer Text, keine Erklaerungen.

DATEN:
[einfügen]
```

### 3.4 Parallele Pipelines (für maximalen Output)

Um die Modelle parallel zu nutzen, können strategisch unabhängige Pfade gleichzeitig laufen:

```
                    [Stratege: GLM 5.1]
                          |
                    Hypothese A
                          |
              +-----------+-----------+
              |                       |
        [Coder Pfad 1]          [Coder Pfad 2]
        Claude Pro              Claude Pro
        Phase 2: Pair-Trading   Phase 3: News-Filter
              |                       |
        [Reviewer 1+2]           [Reviewer 1+2]
        Claude Free #1+#2       Claude Free #1+#2
        (parallel)              (parallel)
              |                       |
        [Backtest]               [Backtest]
        Nutzer (MT5)             Nutzer (MT5)
              |                       |
        [Dokumentator]           [Dokumentator]
        Claude Free #3           Claude Free #3
              |                       |
              +-----------+-----------+
                          |
                    [Stratege: GLM 5.1]
                    Nächste Hypothese
```

**Wichtig:** Code-Pfad 1 und Code-Pfad 2 müssen in **getrennten Git-Branches** laufen, um Merge-Konflikte zu vermeiden. Erst nach Backtest und Dokumentation wird gemerged.

### 3.5 Kontingent-Schonungs-Strategie

Claude Pro hat ein Kontingent (5-faches über 5 Stunden typisch). GLM 5.1 und Claude Free sind unbegrenzt, aber langsamer / weniger fähig.

**Regeln:**
1. **Claude Pro nur für:** Code-Generierung, Backtest-Automatik, Git-Commits, komplexe MQL5-Architektur.
2. **Claude Pro NICHT für:** Code-Review (Claude Free), Formatierung (Claude Free), Strategie-Diskussion (GLM 5.1), Dokumentation (Claude Free).
3. **GLM 5.1 für:** Strategie, Quant-Analyse, Konzept-Review, Pre-Coding-Validation, Post-Backtest-Interpretation.
4. **Claude Free für:** Routine-Reviews, Formatierung, CSV-Pflege, JOURNAL-Einträge, einfache Code-Snippets.

**Täglicher Rhythmus (Vorschlag):**
- Morgen: GLM 5.1 – Hypothese des Tages formulieren (1 Chat)
- Vormittag: Claude Pro – Code generieren + kompilieren (1-2 Chats)
- Mittag: Claude Free #1+#2 parallel – Code reviewen (2 Chats)
- Nachmittag: Nutzer – Backtests im MT5 laufen lassen
- Abend: Claude Free #3 – Backtests dokumentieren (1 Chat)
- Abend: GLM 5.1 – Ergebnisse interpretieren, nächste Hypothese (1 Chat)

**Kontingent-Verbrauch:** ~2 Claude Pro Sessions / Tag (gut im Limit).

---

## Teil 4: Zusätzliche strategische Ideen (übersehen von GLM 5.1)

GLM 5.1 hat sich auf Pair-Trading + 3 sekundäre Filter fokussiert. Hier sind **5 weitere strategische Ideen**, die im Projekt noch nicht getestet wurden und **im MT5-Tester ohne externe Daten testbar** sind. Sie sollten in den Hypothesen-Pool aufgenommen werden, falls Pair-Trading scheitert (was wahrscheinlich ist).

### 4.1 MT5 Calendar API News-Filter (TOP-Priorität)

**Warum übersehen:** GLM 5.1 hat kategorisch ausgeschlossen, daß News-Filter im Tester testbar ist. **Falsch.** MT5 hat seit Build 2155+ eine eingebaute Calendar-API.

**Quellen:**
- `CalendarValueHistory(symbol, from, to, &values[])` – alle Events für ein Symbol
- `CalendarEventById(event_id, event)` – Event-Details
- `CalendarCountryById(country_id, country)` – Länder-Info
- Im Strategy Tester verfügbar für den Backtest-Zeitraum

**Hypothese:** Hohe Volatilität um NFP, Zinsentscheide, CPI ist unberechenbar. Blockieren von Trades 30 min vor bis 30 min nach High-Impact-Events sollte die Trefferquote erhöhen.

**Test-Plan:** 6er-Korb, Fenster A/B, mit vs ohne Filter. PF-Delta pro Symbol berechnen. **A-priori-Erwartung:** PF steigt um 0,05–0,10 in beiden Fenstern, wenn News-Filter aktiv.

**Vorteile:**
- Strukturell anders als alle bisherigen Signale (Zeit-basiert, nicht Preis-basiert)
- Generisch über alle Instrumente (jedes FX-Paar hat News)
- Niedrige Komplexität (~50 Zeilen Code)

### 4.2 Tick-Volume-Profile (zweite Priorität)

**Warum übersehen:** GLM 5.1 hat Tick-Volume nicht erwähnt. MT5 liefert Tick-Volume für Forex (nicht echte Volume, aber proxies gut für Aktivität).

**Hypothese:** Tick-Volume-Spitzen (z.B. > 3σ über rollierendem Mean) korrelieren mit Trend-Fortsetzung oder -Reversal. Zwei Sub-Hypothesen testen:
- **H1a:** Hohe Volume-Spitze bei Breakout = Bestätigung → Trend folgt.
- **H1b:** Hohe Volume-Spitze nach langem Trend = Climax → Reversal.

**Test-Plan:** EMA-Cross-Baseline (id12/id26) + Volume-Bestätigung als Toggle. Vergleich PF mit/ohne. 6er-Korb, Fenster A/B.

**Vorteile:**
- Echte Markt-Mikrostruktur-Information (nicht nur Preis)
- Im MT5-Tester verlässlich verfügbar (Tick-Volume wird modelliert)

### 4.3 Carry-Trade-Basket (dritte Priorität)

**Warum übersehen:** GLM 5.1 hat Carry nur als Nebenidee erwähnt ("Kaufe nur das Paar aus dem Korb, das den positivsten Swap für Long bietet"). Das ist zu schwach – ein Basket-Ansatz ist systematischer.

**Hypothese:** Ein Basket aus Top-3-Carry-Paaren (höchstes positives Swap-Long) übertrifft einen Zufalls-Basket über 30+ Tage Haltezeit.

**Logik:**
- Lese `SymbolInfoInteger(sym, SYMBOL_SWAP_LONG)` für alle 6 Symbole.
- Sortiere absteigend nach Swap-Long.
- Long die Top-3, halte 30 Tage, rolle dann in neue Top-3.
- Vergleich mit Bottom-3 (Anti-Carry) und Random-Basket.

**Test-Plan:** Nur Long, nur Hold, keine aktiven Signale. 30-Tage-Rotation über 2022–2026.

**Vorteile:**
- Echte Carry-Prämie (Swap ist echtes Geld, kein Spread-Artefakt)
- Strukturell anders (Zeit-basiert, nicht Preis-basiert)
- Niedrige Trade-Frequenz → klare Statistik

### 4.4 Volatility-Expansion (nicht ORB)

**Warum übersehen:** GLM 5.1 hat ORB getestet und verworfen. Aber ORB ist ein **zeit-basiertes** Breakout. Volatility-Expansion ist ein **preis-basiertes** Breakout und strukturell verschieden.

**Hypothese:** Wenn aktuelle ATR(H1) > k × rollierender Median-ATR(H1, 100), liegt ein Regime-Wechsel vor. Trade in Richtung des Breakouts.

**Logik:**
- Berechne `ATR(H1, 14)` und `Median(ATR(H1, 14), 100)`.
- Wenn `ATR > 1,5 × Median` UND Close > Open (bullish breakout): Long.
- SL = 1 × ATR, TP = 2 × ATR (festes CRV 2:1).
- 1 Trade pro Expansions-Event, danach 24h Pause.

**Unterschied zu ORB:** ORB triggert zu einer festen Uhrzeit (08:00 EET). Vol-Exp triggert bei einem Preismuster (ATR-Ausbruch). Das sind verschiedene Edge-Quellen.

### 4.5 Cross-Asset-Bestätigung via DXY

**Warum übersehen:** GLM 5.1 hat nicht an Cross-Asset-Signale gedacht.

**Hypothese:** EURUSD-Breakout ist glaubwürdiger, wenn DXY (US-Dollar-Index) gleichzeitig in die entgegengesetzte Richtung bricht. Bestätigt den Makro-Trend.

**Setup:**
- Erstelle Custom Symbol "DXY" in MT5 (Formel aus EURUSD, USDJPY, GBPUSD, USDCAD, USDSEK, USDCHF Gewichtung).
- Alternativ: Verwende USDJPY als inversen DXY-Proxy (Korrelation ~ -0,9).
- Signal: Long EURUSD nur, wenn USDJPY gleichzeitig Short-Signal gibt (Dollar-Schwäche).

**Test-Plan:** EMA-Cross-Baseline + Cross-Asset-Bestätigung als Toggle. 6er-Korb, Fenster A/B.

**Vorteile:**
- Echte Makro-Bestätigung (nicht nur Mikrostruktur)
- Generiert wenige, dafür hochgradig bestätigte Signale

### 4.6 BONUS: Time-of-Day-Patterns (vierte Priorität)

**Warum erwähnenswert:** GLM 5.1 hat ORB mit fester 0-8 Uhr Range getestet. Aber Time-of-Day ist reicher:
- **London Fix** (16:00 London / 17:00 EET): hohe Volatilität, oft Reversals
- **NY Open** (13:30 EET): oft Tages-Hoch/-Tief innerhalb 30 min
- **Tokio Lunch** (06:00-07:00 EET): niedrige Volatilität, Range
- **Frankfurt Open** (09:00 EET): oft tagesdefinierender Move

**Test:** EMA-Cross-Baseline + Filter "nur 09:00-13:00 EET" (Frankfurt+London pre-NY). Vergleich mit "nur 13:30-17:00 EET" (NY+London Fix). A-priori-Erwartung: eine der beiden Sessions schlägt die 24h-Baseline signifikant.

---

## Teil 5: Datenquellen, die WIRKLICH helfen

GLM 5.1 hat Dukascopy-Tick-Data erwähnt, aber nicht erklärt, wie man sie in MT5 integriert. Hier die konkrete Anleitung und drei weitere realistische Datenquellen.

### 5.1 Dukascopy Tick-Data → MT5 Custom Symbol (How-to)

**Schritt-folge:**
1. **Download:** [Dukascopy Historical Data Feed](https://www.dukascopy.com/swiss/english/marketwatch/historical/) – kostenlos, Tick-Auflösung ab 2003.
2. **Format:** Dukascopy liefert `.csv` oder `.bin` (Bi5-Format, komprimiert).
3. **Konvertierung:** Python-Script (z.B. [dukascopy-python](https://github.com/indicee/dukascopy-node) oder eigener Parser) → MT5-kompatibles CSV: `YYYY.MM.DD HH:MM:SS.fff,Bid,Ask,Volume`.
4. **Import in MT5:**
   - `Tools → Options → Server → Custom Symbols`
   - Neues Symbol erstellen (z.B. "EURUSD_DUKA")
   - `Import from File` → CSV auswählen
   - Mapping: Time, Bid, Ask, Volume
5. **Verwendung im EA:** Input-Parameter auf "EURUSD_DUKA" setzen.

**Wichtige Vorbehalte:**
- Custom Symbols im Tester haben **eingeschränkten Tick-Modus**: "Every tick based on real ticks" ist verfügbar, aber Performance ist langsamer.
- Bid/Ask-Spread ist historisch realistisch (im Gegensatz zu MetaQuotes-Demo, wo Spread oft idealisiert ist).
- Dukascopy ist ein ECN-Broker – Spreads sind eng. Für Retail-Broker-Simulation muß der Spread künstlich verbreitert werden (z.B. +0,5 Pips).

**Empfehlung für dieses Projekt:** Zunächst mit MetaQuotes-Demo-Daten testen (schnell, einfach). Erst wenn ein vielversprechender Edge gefunden wird, mit Dukascopy-Daten validieren (slow, aber realistisch).

### 5.2 MT5 Custom Symbols für Cross-Asset (DXY)

**Warum nützlich:** DXY (US Dollar Index) ist nicht als Standard-Symbol bei den meisten Brokern verfügbar. Aber man kann ihn als Custom Symbol berechnen.

**Formel:**
```
DXY = 50.14348112 × EURUSD^(-0.576) × USDJPY^(0.136) × GBPUSD^(-0.119)
      × USDCAD^(0.091) × USDSEK^(0.042) × USDCHF^(0.036)
```

**Setup:**
1. Python-Script (außerhalb Repos) berechnet DXY aus M1-Daten der 6 Komponenten.
2. Export als CSV.
3. Import in MT5 als Custom Symbol "DXY_CUSTOM".
4. EA liest `iClose("DXY_CUSTOM", PERIOD_H1, 1)` für Cross-Asset-Bestätigung.

**Hinweis:** Da die Berechnung in Python läuft, muß dies als **explizite Ausnahme** in `CLAUDE.md` dokumentiert werden ("einmaliger Setup-Schritt, nicht Teil der Pipeline").

### 5.3 Cointegration-Test in MQL5 (kein Python!)

Wie in Teil 1.2.3 argumentiert: Cointegration-Tests in MQL5 statt Python, um den Stack sauber zu halten.

**Implementierungsskizze für `scripts/cointegration_check.mq5`:**
```mql5
// Hauptfunktionen:
// 1. Least-Squares-Regression: Cov(A,B)/Var(B) = beta
// 2. Spread = Log(A) - beta * Log(B)
// 3. ADF-Test (Augmented Dickey-Fuller):
//    Regression: Delta_Spread_t = alpha + rho * Spread_{t-1} + phi * Delta_Spread_{t-1} + e_t
//    t-Statistik für rho = 0 (Nullhypothese: Unit Root = NICHT cointegriert)
// 4. Kritische Werte (MacKinnon 1991): 1%=-3.43, 5%=-2.86, 10%=-2.57

// MQL5 hat kein Matrix-Inverse, aber fuer einfache OLS-Regression reicht:
// beta = sum((A - meanA)*(B - meanB)) / sum((B - meanB)^2)

// Lag-Order-Wahl: Schwarz Criterion über Lag 0-3 iterieren, Minimum wählen
```

**Aufwand:** ~150-200 Zeilen Code, gut an einem Tag zu schaffen. Implementiert einmal, dann für jedes Paar wiederverwendbar.

**Alternative:** GLM 5.1 kann den Code schreiben (Stratege-Rolle), Claude Code reviewt und kompiliert. Das ist ein guter Use-Case für die Modell-Aufteilung.

### 5.4 Walk-Forward-Demo-Test (die unterschätzte Datenquelle)

**Warum nützlich:** Jeder Backtest, der im MT5-Tester läuft, leidet unter Modellierungs-Limitationen (Spread, Slippage, Tick-Auflösung für sekundäre Symbole). Der **Demo-Server** liefert echte Ticks für alle Symbole.

**Setup:**
1. EA auf Demo-Konto (MT5 läuft durch, EURUSD H1 Chart).
2. EA schreibt jeden Trade in `Common\Files\live_trades.csv` mit denselben Spalten wie Backtest-Output.
3. Nach 30 Tagen: vergleiche Live-Trades mit Backtest-Trades desselben Zeitraums.
4. **Konsistenz-Check:** Wenn < 70% der Backtest-Trades auch in Live auftreten → Backtest ist artefaktisch. Wenn > 90% → Backtest ist realistisch, Edge-Bewertung verläßlich.

**Wichtig:** Dies ersetzt keinen Backtest, sondern **validiert** ihn. Es ist die billigste "Datenquelle", weil sie schon existiert – man muß sie nur nutzen.

**Empfehlung:** Parallel zum nächsten Backtest-Sprint den Haupt-EA auf Demo laufen lassen (nur EURUSD, nur Long, nur 1-%-Risiko), um die Backtest-Qualität zu validieren.

### 5.5 OnTester() um Macro-Stats erweitern

**Was übersehen wurde:** Der bestehende `OnTester()` schreibt Standard-Kennzahlen. Erweitern um:
- **Average Hold Time (Stunden)** – Diagnostik für Overtrading
- **Win/Loss Ratio by Hour-of-Day** – erfasst saisonale Muster
- **Win/Loss Ratio by Day-of-Week** – erfasst Wochentag-Effekte
- **Maximum Concurrent Trades** – Margen-Auslastung
- **Average MFE/MAE** – wie weit ging der Trade ins Plus/Minus, bevor er geschlossen wurde

Diese Stats kosten nichts extra (sind beim Backtest ohnehin im Speicher) und liefern **Diagnostik**, die bei der Ideen-Entwicklung hilft.

---

## Teil 6: Konkreter Aktionsplan

### 6.1 Heute noch (13.07.2026)

**1. GLM 5.1 (dieser Chat) – Cointegration-Hypothese bewerten**
- Frage an GLM: "Bewerte kritisch, ob EURUSD/GBPUSD cointegriert sind, basierend auf den bekannten Strukturbrüchen (Brexit 2016, Gilt-Krise 2022, BoE-vs-ECB-Divergenz 2023-24). Sollten wir den Cointegration-Test überhaupt erst laufen lassen, oder direkt zu Alternativen?"
- 30 min Chat

**2. Claude Code (Pro) – Phase 1 implementieren**
- Prompt aus Teil 2 (nur Phase 1!) in Claude Code werfen.
- `scripts/cointegration_check.mq5` erstellen lassen.
- Kompilieren, im MT5-Tester laufen lassen für 15 Paar-Kombinationen.
- 1-2 h Claude Code Session

**3. Claude Free #3 – Ergebnisse dokumentieren**
- Rohe Cointegration-Ergebnisse in Claude Free werfen.
- `KONTEXT.md`-Sektion "## Cointegration-Pre-Check (Phase 1)" formatieren lassen.
- 20 min Claude Free Session

### 6.2 Diese Woche (14.-20.07.2026)

**Entscheidungspfad basierend auf Phase-1-Ergebnis:**

| Phase-1-Ergebnis | Aktion |
|---|---|
| ≥1 Paar cointegriert | Phase 2 (Pair-Trading-EA) bauen. 2-3 Tage Claude Code. |
| Kein Paar cointegriert | Direkt zu Phase 3: News-Filter + Saisonalität. 2-3 Tage Claude Code. |
| Cointegriert, aber Pair-Trading scheitert | Phase 3 + 4.2 (Tick-Volume) + 4.3 (Carry-Basket) parallel. |

**Parallel in jedem Fall:**
- Claude Free #1+#2: Code-Reviews parallel zur Entwicklung
- GLM 5.1: Tägliche Strategie-Session (1 Chat pro Tag)
- Claude Free #3: Jeden Backtest dokumentieren (1 Chat pro Backtest-Serie)
- Demo-Test: Haupt-EA auf Demo laufen lassen für Backtest-Validierung

### 6.3 Nächster Sprint (3-4 Wochen)

Falls Pair-Trading + News-Filter + Saisonalität alle scheitern (realistisches Szenario):
1. **Tick-Volume-Profile** (Teil 4.2) implementieren und testen
2. **Carry-Trade-Basket** (Teil 4.3) als orthogonalen Ansatz testen
3. **Volatility-Expansion** (Teil 4.4) als Breakout-Alternative testen
4. **Cross-Asset-DXY** (Teil 4.5) einmalig als Bestätigungs-Signal testen

**Wichtig:** Nichts davon parallel optimieren. **Eine Idee pro Sprint, isoliert testen, sauber verwerfen oder bestätigen.** Das ist die Disziplin, die das Projekt bisher ausgezeichnet hat.

### 6.4 Notausstieg: Wann das Projekt stoppen sollte

Ehrlicher Haltepunkt: Wenn nach **insgesamt 100 Backtests** (wir sind bei 61) kein einziger |z| > 2 Edge gefunden wurde, sollten folgende Optionen geprüft werden:

1. **Pivot auf andere Märkte:** Indices (DAX, S&P) statt FX. Weniger effizient, mehr Edge-Potential.
2. **Pivot auf längere Haltezeiten:** Swing/Position-Trading statt Intraday. Swap wird zum Freund, nicht Feind.
3. **Pivot auf manuelle Discretion:** EA nur als Signal-Generator, finale Entscheidung durch Nutzer.
4. **Akzeptanz:** Kein Edge gefunden → Projekt als Lernprojekt abschließen, kein Live-Einsatz.

**Wichtig:** Das ist KEIN Scheitern, sondern eine ehrliche quantitative Erkenntnis. 61 Backtests mit sauberer Methodik sind ein enormer Lerngewinn.

---

## Anhang A: Diff vom GLM-5.1-Prompt zum verbesserten Prompt

| Aspekt | GLM 5.1 (Original) | Verbessert (Teil 2) |
|---|---|---|
| Pre-Check | Python-Cointegration vorgeschlagen | MQL5-Script, gegen `CLAUDE.md`-Regeln verstoßen vermieden |
| Look-Ahead | Nur allgemein erwähnt | Explizit `iClose(..., 1)` vs `iClose(..., 0)` spezifiziert |
| Transaktionskosten | Nur Swap erwähnt | 2× Spread + 2× Kommission + Swap-Modell, Kosten-Check vor Einstieg |
| OnTester | "Nutze bestehenden Code" vage | Explizite Format-Kompatibilität zu `ema_mtf_v3.mq5`, neue Spalten am Ende |
| Symbol-Suffix | Nicht erwähnt | `SymbolSelect()` + `SymbolInfoString(SYMBOL_SYMBOL)` |
| Tester-Limitation | Nicht erwähnt | Log-Warning + `test_mode`-Reporting in `OnTester()` |
| News-Filter | Ausgeschlossen ("braucht externen Feed") | MT5 Calendar API als Phase 3.1 |
| Statistik-Review | Eine Review-Stufe | Zwei parallele Reviewer (Look-Ahead + Statistik) |
| Workflow | Linear, 4 Stufen | Parallele Pipelines + 4 Quality-Gates |
| Strategie-Ideen | Pair-Trading + 3 Filter | +5 zusätzliche Ideen (Calendar, Volume, Carry, Vol-Exp, Cross-Asset) |
| Aktionsplan | 5-Schritte-Liste | Heute/Diese Woche/Nächster Sprint/Notausstieg |

## Anhang B: Checkliste für jede neue Strategie-Idee

Bevor eine neue Idee in den Workflow geht:

- [ ] Hypothese in ≤ 3 Sätzen formuliert?
- [ ] A-priori-Parameter festgelegt (kein Optimieren)?
- [ ] Test-Plan mit Fenster A/B + ≥1 Zweitinstrument definiert?
- [ ] Abbruch-Kriterium numerisch festgelegt?
- [ ] Erfolgskriterien numerisch festgelegt (|z| > 2, PF > 1)?
- [ ] Strukturell verschieden von allen 6 verworfenen Strategie-Familien?
- [ ] Im MT5-Tester ohne externe Daten testbar?
- [ ] Transaktionskosten-Modell berücksichtigt?
- [ ] Look-Ahead-Bias ausgeschlossen (Code-Review)?
- [ ] OnTester-Format kompatibel zu bestehendem Schema?

Wenn alle 10 Fragen mit "Ja" beantwortet sind → Idee in den Workflow aufnehmen.
Sonst → Idee verwerfen oder überarbeiten.

---

_Dokument erstellt am 2026-07-13. Lebendes Dokument – bei neuen Erkenntnissen aktualisieren und in Repo committen._

