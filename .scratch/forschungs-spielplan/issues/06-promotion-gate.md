# 06 -- Promotion-Gate Backtest -> Demo-Paper -> Live

Type: grilling
Status: resolved
Blocked by: 05

## Question

Nach welchem Gate wandert eine Strategie durch die Stufen?
- Backtest -> Demo-Paper: welche Schwellen aus Ticket 05 muessen erfuellt sein?
- Demo-Paper-Dauer: wie lange, mit welcher Mindest-Trade-Zahl, welche
  Live-vs-Backtest-Abweichung ist noch akzeptabel?
- Demo-Paper -> Live: Kriterien -- und die Eiserne Regel, dass der Schritt zu Live
  ausschliesslich manuell durch den Nutzer erfolgt.
- Abbruch/Rueckstufung: wann faellt eine Strategie zurueck oder raus?

Blockiert von 05, weil die Promotion-Schwellen direkt aus dem Erfolgs-/Abbruch-
Kriterium des Protokolls folgen.

## Answer

Das Promotion-Gate hat drei Stufen und funktioniert auch rueckwaerts.

### Stufe 1: Backtest -> Demo-Paper
Exakt das zusammengesetzte Erfolgs-Tor aus Ticket 05 (WFE > 0,5 ueber >= 5
WF-Zyklen, Robustheit/Plateau, Deflated Sharpe > 0,95, PF-Korridor 1,1-1,4,
Lockbox haelt). Keine eigene Schwelle -- 05 IST die Schwelle.

### Stufe 2: Demo-Paper-Phase bestanden (alle Bedingungen zusammen)
Demo-Paper ist das ehrlichste OOS (Ticket 02) -- die ultimative Lockbox.
Bestanden erst, wenn ALLE erfuellt sind (was spaeter eintritt, zaehlt):
- Mindestdauer >= 3 Monate echtes Demo-Paper (mehrere Marktphasen).
- Mindestens 30 live-simulierte Trades.
- Nicht-Kollaps: Demo-PF >= 1,0 UND nicht mehr als ~30 % unter Backtest-PF;
  max. Drawdown nicht > ~50 % ueber Backtest-DD.
Zeit + Menge + Nicht-Kollaps muessen gemeinsam erfuellt sein.

### Stufe 3: Demo-Paper -> Live (Eiserne Regel: nur manuell)
- Voraussetzung: Stufe 2 vollstaendig bestanden, keine Abkuerzung.
- Bewusste manuelle Freigabe durch den Nutzer, kurz dokumentiert (Datum +
  Begruendung in JOURNAL.md). Kein Skript darf den Live-Schritt ausloesen.
- Live-Start klein: minimale Positionsgroesse / reduziertes Risiko-%; Hochskalieren
  erst nach >= 20-30 echten Live-Trades, die Live == Demo bestaetigen.
- Nie mehrere frische Strategien gleichzeitig live -- eine nach der anderen.

### Rueckwaerts: Abbruch, Rueckstufung, Notausstieg
- Waehrend Demo-Paper: reisst eine Stufe-2-Schwelle mittendrin hart (PF < 1,0 ueber
  einen Block, DD sprengt 50 %), sofort abbrechen -- nicht die 3 Monate aussitzen.
  Zurueck zum Backtest oder zu den Akten (Fazit in backtests.csv).
- Live-Rueckstufung: verhaelt sich Live ueber >= 20 Live-Trades schlechter als Demo
  (PF < 1,0 oder DD ueber harter Obergrenze) -> zurueck auf Demo oder stilllegen.
  Nie nachschiessen, nie Regeln lockern.
- Harter Kill-Switch: feste maximale Verlust-/Drawdown-Grenze (an die bestehende
  Tagesverlust-/Notausstieg-Regel gekoppelt), bei der eine Live-Strategie
  bedingungslos vom Netz geht -- kein Ermessen.
- Kein Martingale/Grid zum Aufholen -- Eiserne Regel bleibt auch im
  Rueckstufungsfall unantastbar.

### Folgen / Nebel
- Konvention: Live-Freigaben werden in JOURNAL.md dokumentiert (Datum + Grund).
- Der konkrete Zahlenwert des Live-Kill-Switch bleibt offen gelassen (an bestehende
  Notausstieg-Regel gekoppelt) -- kann bei der ersten realen Live-Kandidatin
  praezisiert werden.
