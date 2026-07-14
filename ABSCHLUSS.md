# Abschluss Phase 1–4: Lernprojekt-Retrospektive

_Stand: 14.07.2026 · Claude Code_

Dieses Dokument schliesst die Forschungsphasen 1–4 ehrlich ab. Es fasst
zusammen, **was getestet wurde, was dabei herauskam und was wir gelernt
haben** – und richtet die naechste Runde ("bessere Strategien") methodisch
sauberer aus.

Kurz gesagt: **Nach 163 dokumentierten Backtests ueber 10 Strategie-Familien
hat keine Idee einen robusten, instrumentuebergreifenden, kosten- und
regime-festen Vorteil gezeigt.** Das ist kein Scheitern, sondern ein
serioeses Forschungsergebnis: Wir haben eine ganze Reihe populaerer
Retail-Strategien mit sauberer Methodik *widerlegt* statt uns etwas
schoenzurechnen.

---

## Was wir getestet haben (10 Familien)

| # | Strategie-Familie | Kern-Idee | Ergebnis |
|---|---|---|---|
| 1 | EMA-Kreuz (+ MTF-Bias) | 9/21-Kreuz, hoehere Zeitebene als Trend-Filter | Auf EURUSD profitabel, aber **Overfit** – uebertraegt sich nicht mal auf GBPUSD |
| 2 | Gewinnsicherung | Break-Even + Teil-TP auf EMA-Kreuz | Verbesserung war **Trend-Artefakt** (2022-2023), Fenster B negativ |
| 3 | Mean-Reversion "raus im Plus" | max. Trefferquote, sofort Gewinn sichern | **Winrate-Falle**: 83-91 % Treffer, trotzdem netto Minus |
| 4 | Volatilitaets-Filter | nur handeln bei hoher ATR-D1 | Half nur EURUSD, **generalisiert nicht** (GBPUSD Fenster B faellt) |
| 5 | Struktur-Swing | Fractal-Swings + MTF-Trend, kein Indikator | Gepoolt PF < 1, z negativ – **Rauschen** |
| 6 | Opening-Range-Breakout | Ausbruch aus ruhiger Session | Signifikant **NEGATIV** (z = -2,61) – FX-Ranges werden gefadet |
| 7 | Pair-Trading (Cointegration) | Log-Spread zweier cointegrierter Paare | **OOS durchgefallen** – Cointegration im Sample ≠ handelbar |
| 8 | Saisonalitaet | nur in London/NY-Stunden handeln | **Kein Edge** – Fenster B bleibt negativ |
| 9 | Carry-Basket | Seite mit guenstigerem Swap halten | **Kein Edge** – Retail-Swaps oft beidseitig negativ |
| 10 | Stock Mean-Reversion RSI(2) | "Buy the Dip" in Aktien-Aufwaertstrend | z > 2 war **Data Snooping**; Kontrolle: nur **Long-Beta**, kein Timing-Alpha |

Details je Familie: `KONTEXT.md` (Backtest-Chronik 1–20), Rohzahlen in
`backtests.csv`.

---

## Die wertvollen Lektionen (das eigentliche Ergebnis)

Diese Regeln sind mit **eigenen Daten** belegt – nicht aus einem Buch
abgeschrieben. Sie sind der bleibende Gewinn des Projekts:

1. **Hohe Trefferquote ≠ Gewinn.** 91 % Treffer und trotzdem Minus, wenn ein
   Verlust 65 Gewinne loescht. Was zaehlt, ist die **Erwartung**
   (Groesse × Haeufigkeit), nicht die Quote. Genau die Falle hinter
   "90 % Winrate"-Marketing.

2. **Ein Instrument beweist nichts.** Der schoene EURUSD-Gewinn uebertrug sich
   nicht mal auf das eng verwandte GBPUSD → es war Kurvenanpassung, kein
   Markt-Vorteil. Konsequenz: **ueber viele Instrumente poolen** und mit
   z-Score messen.

3. **Cointegration im Rueckblick ≠ handelbar in Zukunft.** Das *staerker*
   cointegrierte Paar war der *schlechtere* Trader. Statistische Eigenschaft
   im Sample sagt den OOS-Edge nicht voraus.

4. **Data Snooping ist heimtueckisch.** Ein z = 2,46 entstand nur, weil
   nachtraeglich die 2 schlechtesten Aktien gestrichen wurden – exakt der
   Streich, der z maximiert (Nachweis: `tools/snoop_sensitivity.py`). **Pool
   nie nach Sichtung der Ergebnisse veraendern.**

5. **Long-only-Gewinne gegen Beta pruefen.** Eine Long-Strategie verdient im
   Bullenmarkt auch ohne Koennen. Der Kontroll-Test (Signal vs. "einfach long
   im Trend" vs. Zufall, `tools/control_experiment.py`) zeigte: das RSI-Timing
   schlaegt reine Beta in **keinem** Fenster. **Immer gegen einen
   Beta-/Zufalls-Benchmark testen, nie roh.**

6. **Kosten realistisch ansetzen.** Realistische Aktien-Reibung frass 25-35 %
   der duennen Kante und drueckte den besten Fall unter die Signifikanz.

7. **Kleine Stichprobe = kein Urteil.** z waechst mit √n; unter ~300-400
   Trades ist fast alles "Rauschen". Die **Pooling-Methodik** loest das und
   ist das wichtigste Werkzeug, das wir gebaut haben.

---

## Der Werkzeugkasten, der bleibt

- **Pooling-Test** (`tools/pool_backtests.py`, `tools/pool_from_csv.py`) –
  buendelt Trades ueber einen Korb, rechnet einen belastbaren z-Wert.
- **Validierung** (`tools/validate_backtests.py`) – rechnet jede CSV-Zeile
  unabhaengig nach.
- **Data-Snooping-Audit** (`tools/snoop_sensitivity.py`) – zeigt, wie stark
  ein Ergebnis von der Symbol-Auswahl abhaengt.
- **Beta-Kontrolle** (`tools/control_experiment.py` + `experts/export_daily.mq5`)
  – trennt echtes Timing von blossem Markt-Rueckenwind.
- **Test-Disziplin** (`tools/checklist_new_strategy.md`) – 2 OOS-Fenster +
  Zweitinstrument + |z| > 2.

Alle EAs bleiben als saubere Test-Gerueste im Repo.

---

## Sicherheit (unveraendert)

Es gab **keinen** Demo-Einsatz mit Gewinnerwartung und **kein** Live-Trading.
Die Reihenfolge bleibt: Backtest → Demo-Paper (nur bei belegtem Edge) → Live
(nur manuell durch den Nutzer). Keine Idee hat diese Huerde genommen, also
blieb es korrekterweise beim Backtest.

---

## Naechste Runde: "bessere Strategien" – aber mit Leitplanken

Die 7 Lektionen ergeben eine harte Aufnahmepruefung fuer jede neue Idee.
**Eine neue Strategie kommt nur in Betracht, wenn sie strukturell anders ist
und die bekannten Fallen vermeidet:**

- ❌ **Kein** reines Long-only-Trendreiten mehr (ist immer nur Beta).
- ❌ **Kein** Feintuning bekannter, verworfener Signale.
- ✅ Wird von Anfang an **gegen einen Beta-/Zufalls-Benchmark** gemessen, nicht
  roh (Differenz-z in BEIDEN Fenstern).
- ✅ Wird **ueber einen Korb gepoolt** (genug Trades) und out-of-sample
  geprueft (Fenster A/B), Symbol-Pool **vorher** festgelegt.
- ✅ Realistische **Kosten** von Anfang an im Modell.

Kandidaten-Richtungen fuer Phase 5 stehen in `KONTEXT.md` unter
"Phase 5 – Neue Signalfamilie". Die Entscheidung, welche zuerst, trifft der
Nutzer.
