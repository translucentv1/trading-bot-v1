# 01 -- Datenlage Nasdaq-Einzelaktien in MT5

Type: research
Status: resolved
Blocked by: -

## Question

Welche Datenlage steht fuer Nasdaq-Einzelaktien im MetaTrader 5 realistisch zur
Verfuegung? Konkret:
- Bieten typische MT5-Broker ueberhaupt US-Einzelaktien (CFDs) als Symbole, oder
  nur Indizes/Futures (US100/NAS100)?
- Wie tief reicht die verfuegbare Kurshistorie (Jahre, Timeframes) fuer den
  Strategy Tester -- reicht es fuer Fenster A (2022-2023) und B (2024-2026)?
- Datenqualitaet: Ticks vs. M1-OHLC, Luecken, Dividenden-/Split-Anpassung.
- Welche Broker/Datenquellen sind fuer ein Solo-Demo-Konto praktikabel?

Ergebnis ist die Faktenbasis fuer Ticket 04 (Marktfokus) und 07 (Broker-Realitaet).

## Answer

### Bieten MT5-Broker US-Einzelaktien oder nur Indizes?
- Ja, es gibt US-Einzelaktien -- aber ausschliesslich als **CFDs**, nicht als
  echte Aktien. Anbieter mit US-Share-CFDs in MT5 sind u.a. Pepperstone, IC
  Markets, FxPro (Namen wie AAPL, TSLA, NVDA, AMZN, MSFT).
- Wichtige Einschraenkung: Diese Broker sind international/offshore. **US-Kunden
  duerfen keine CFDs handeln** (regulatorisch verboten). Fuer ein Solo-Demo-Konto
  ausserhalb der USA (z.B. EU/CySEC/ASIC-Entities) sind sie aber zugaenglich.
- Parallel existieren die Index-Produkte US100/NAS100 (Nasdaq-100 CFD) und
  US-Tech-Futures. Diese sind viel breiter verfuegbar und liquider als
  Einzelaktien-CFDs.
- Achtung Symbol-Verwechslung: US100/NAS100 ist ein Index-Derivat, kein Korb aus
  echten Einzelaktien -- Einzelaktien-Strategien lassen sich damit NICHT abbilden.

### Historientiefe im Strategy Tester -- reicht sie fuer 2022-2023 und 2024-2026?
- MT5 laedt beim ersten Testlauf die **gesamte vom Broker bereitgestellte
  Historie** herunter. Es gibt kein universelles Limit -- die Tiefe haengt
  komplett vom Broker ab.
- Realitaet bei Aktien-CFDs: Die Historie beginnt oft erst, wann der Broker das
  Symbol aufgenommen hat. Viele Broker fuehren Serverdaten erst ab ca. 2015-2016,
  einzelne Aktien-CFDs teils noch spaeter/lueckenhaft.
- Fenster B (2024-2026) ist bei aktiven Brokern meist gut abgedeckt.
- Fenster A (2022-2023) ist **nicht garantiert** -- muss pro Broker und pro
  konkretem Symbol geprueft werden (Symbol im MarketWatch, dann "Download" im
  Symbols-Dialog / History-Center). Bei jungen oder spaeter gelisteten Symbolen
  kann der Tester den Startzeitpunkt automatisch nach vorne schieben.
- Tester-Minimum: mind. 100 Bars der Timeframe vor Modellstart; hoehere
  Timeframes brauchen entsprechend mehr Vorlauf.

### Datenqualitaet: Ticks vs. M1-OHLC, Luecken, Splits/Dividenden
- Modellierung: "Every tick based on real ticks" liefert die hoechste Qualitaet,
  ist aber bei Aktien-CFDs stark broker-abhaengig; oft liegen nur M1-OHLC vor,
  aus denen der Tester Ticks generiert ("Every tick"/"1 minute OHLC"). Fuer
  robuste Ergebnisse ist die reale Tick-Verfuegbarkeit zu pruefen.
- Luecken: Aktien-CFDs handeln nur zu US-Kassa-Boersenzeiten -> naturgemaess
  Overnight-/Wochenend-Gaps, plus Feiertage. Das ist normal, kein Datenfehler,
  muss aber in der Strategie (Session-Filter, Gap-Handling) beruecksichtigt
  werden.
- Splits: Bei einem realen Split wird die CFD-Position im Verhaeltnis angepasst
  (z.B. 2:1 -> doppelte Menge, halber Preis). Ob die **historische Kursreihe** im
  Tester rueckwirkend split-bereinigt ist, ist NICHT garantiert -- unbereinigte
  Reihen zeigen kuenstliche Preissprunge am Split-Datum. Vor Backtests mit
  Split-Titeln (z.B. TSLA 2022, NVDA 2024) die Reihe visuell auf Spruenge pruefen.
- Dividenden: Werden bei CFDs ueber Cash-Anpassung am Ex-Tag verrechnet (Long
  bekommt gutgeschrieben, Short belastet), NICHT ueber den Kurs. Der
  Strategy Tester bildet diese Dividenden-Cashflows in der Regel **nicht** ab ->
  systematische Verzerrung bei Dividendentiteln und langen Halteperioden.

### Praktikabel fuer ein Solo-Demo-Konto
- Am robustesten/breitesten verfuegbar: Index-CFD **US100/NAS100** -- tiefe,
  saubere, liquide Historie, gut fuer den Tester. Aber: keine Einzelaktien.
- Fuer echte Nasdaq-Einzelaktien: Demo-Konto bei einem Broker mit dediziertem
  US-Share-CFD-Angebot (Pepperstone, IC Markets, FxPro o.ae.) eroeffnen und PRO
  SYMBOL die verfuegbare Historientiefe + Datenqualitaet im History-Center
  verifizieren, bevor man auf diese Datenbasis baut.
- Alternative bei zu kurzer/lueckenhafter Broker-Historie: Fremd-/Tick-Daten
  importieren (Custom Symbol in MT5, z.B. via Tickstory oder eigenem CSV-Import)
  -- mehr Aufwand, aber laengere/sauberere Reihen; dann aber selbst fuer
  Split-/Dividenden-Bereinigung verantwortlich.

### Empfehlung fuer die Faktenbasis (Ticket 04/07)
- Nicht annehmen, dass beliebige Nasdaq-Einzelaktien in MT5 mit sauberer
  2022-2026-Historie "einfach da" sind. Realistische Annahme: Einzelaktien-CFDs
  nur bei bestimmten Offshore-Brokern, Historientiefe & Qualitaet variabel und
  symbol-individuell zu pruefen; Split-/Dividenden-Effekte sind eine bekannte
  Fehlerquelle im Tester.
- Sicherste Faktenbasis fuer belastbare Backtests: entweder US100/NAS100 als
  Index (breite, saubere Daten, aber keine Einzeltitel) ODER ein konkreter
  Broker + verifizierte Symbolliste + verifizierte Historientiefe je Fenster,
  ggf. ergaenzt durch importierte Tick-Daten.
- Unsicherheiten offen: Exakte Historientiefe pro Symbol/Broker liess sich ohne
  Live-Zugang zu einem konkreten Demo-Server nicht abschliessend beziffern --
  das bleibt eine empirische Pruefung im MT5 History-Center. Keine Anlageberatung.

### Quellen (URLs)
- https://www.metatrader5.com/en/terminal/help/algotrading/test_preparation
- https://www.metatrader5.com/en/terminal/help/algotrading/testing
- https://www.stockbrokers.com/guides/best-metatrader-brokers
- https://brokerchooser.com/best-brokers/best-forex-brokers/brokers-for-metatrader-5-in-the-united-states
- https://pepperstone.com/en/trading/instruments/share-cfds/us-shares/
- https://www.compareforexbrokers.com/reviews/pepperstone-vs-ic-markets/
- https://www.contracts-for-difference.com/Dividend-stock-split.html
- https://www.cmcmarkets.com/en-gb/learn-cfd-trading/corporate-actions
- https://www.interactivebrokers.co.uk/en/trading/cfd-corp-actions.php
- https://windsorbrokers.com/knowledge-base/trading-platform/how-do-i-access-historical-data-on-the-mt5/
- https://tickstory.com/how-to-import-tick-data-into-metatrader-5/
- https://support.eareview.net/support/solutions/articles/19000162309-how-to-backtest-in-mt5-with-100-history-quality
