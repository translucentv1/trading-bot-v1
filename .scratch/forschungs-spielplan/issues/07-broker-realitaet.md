# 07 -- Broker-Realitaet im Test: Kosten- & Slippage-Modellierung

Type: grilling
Status: resolved
Blocked by: 01 (resolved)

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

## Answer

Jeder Wertungs-Lauf muss die volle Broker-Realitaet einpreisen; im Zweifel wird
teurer gerechnet. Vier Pflicht-Bausteine, alle in die .ini-Vorlage (Ticket 08) fest
hinterlegt, damit kein Lauf "aus Versehen" kostenlos handelt.

### 1. Ausfuehrungsmodell: "Jeder Tick auf Basis realer Ticks" (Pflicht)
Nur echte Broker-Ticks bilden Spread-Schwankung, Slippage und Intrabar-Reihenfolge
real ab. Pflicht fuer jeden Lauf, der ins Erfolgs-Tor / in DSR-N / in die Lockbox
zaehlt. Schnellere Modelle (M1 OHLC, nur Eroeffnungspreise) nur fuer grobes
Vorab-Sieben (Stufe 0 der Abbruch-Treppe) -- ein solcher Lauf darf NIE gewertet
werden. Koppelt an 01/04: reale Ticks setzen voraus, dass der Broker sie fuer
Symbol/Fenster liefert (Index US100 i.d.R. ja, Offshore-Einzelaktien fraglich).

### 2. Spread: real variabel + Stress-Zweitlauf
Realer variabler Spread ist die ehrliche Basis (kommt bei realen Ticks automatisch
mit) und bildet die teuren Momente (News, Handelsschluss) ab. Zusaetzlich ein
Robustheits-Zweitlauf mit bewusst ueberhoehtem fixem Spread (~1,5x Median). Bricht
der Edge dabei zusammen, war er ein Spread-Artefakt -- raus.

### 3. Kommission & Slippage: explizite Pflicht-Parameter
MT5 zieht beides NICHT automatisch. Beide konservativ, dokumentiert pro Instrument:
- Kommission: tatsaechlichen Broker-Wert eintragen (aus 04-Datencheck ablesen),
  round-turn = 2x pro Lot. Solange unbekannt -> konservativ hoch ansetzen.
- Slippage: pauschal 1-2 Points pro Trade-Seite, fuer Stop-Orders am oberen Ende;
  im Spread-Stresstest (Baustein 2) mit hochdrehen.
Kernprinzip: im Zweifel teurer -- lieber einen echten Edge faelschlich verwerfen
als einen Scheingewinn durchwinken.

### 4. Kosten-Ertrags-Schranke (neues Abbruch-Kriterium)
Zusaetzlich zur >=30-Trades-Regel aus 05: Kosten pro Trade (Spread + Kommission +
Slippage) duerfen hoechstens ~1/3 des durchschnittlichen Brutto-Edges pro Trade
ausmachen. Sonst ist die Strategie zu kostenempfindlich, um live zu ueberleben.
Einordnung: wird Teil von Stufe 2 der Abbruch-Treppe (erste OOS-Pruefung) -- faellt
die Schranke, raus, bevor Walk-Forward-Zyklen verbrannt werden. Schliesst die
Luecke, durch die Mikro-Edge-Scalping bisher "im Backtest schoen" aussah.

### Verankerung
- Bausteine 1-3 = Tester-/.ini-Konfiguration (Ticket 08 baut sie ein).
- Baustein 4 = Erweiterung der Abbruch-Treppe aus Ticket 05 (Stufe 2).
- Reale Kostenwerte kommen aus dem Broker-/Symbol-Datencheck (01/04).
