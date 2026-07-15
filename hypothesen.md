# Hypothesen-Register

Jede Strategie-Idee wird hier VOR dem ersten Backtest festgeschrieben und ist
danach unveraenderlich (Anti-HARKing, siehe Spielplan Abschnitt 1 /
`.scratch/forschungs-spielplan/spec.md`). Der `hypothese`-Key steht in
`backtests.csv`; der ausfuehrliche Eintrag steht hier.

## Regeln (Kurzfassung aus Ticket 09)

1. **Mechanismus zuerst.** Kein plausibler oekonomischer Mechanismus -> kein
   Backtest. Reine Data-Mining-/Screening-Treffer sind nur *Kandidaten-Notizen*
   (Abschnitt unten), bis sie einen Mechanismus finden.
2. **4 Felder, vor dem Lauf fix.** Wird das vorhergesagte Muster nachtraeglich an
   die Daten angepasst -> Hypothese verbrannt, nicht "angepasst".
3. **Priorisierung:** staerkster Mechanismus x billigste Widerlegung, NICHT nach
   vermutetem Gewinn.
4. **Marktbindung (Ticket 04):** Stufe 1 (jetzt, US100-Index) nur Einzelinstrument-
   Mechanismen; Querschnitts-Ideen (relative Staerke etc.) erst Phase-4b.

## Key-Schema

`H-JJJJ-MM-<symbol>-<kurz>` -- z.B. `H-2026-07-US100-ovngap`. Der Key ist der Wert
in der Spalte `hypothese` von `backtests.csv`.

## Format-Vorlage

```
### H-JJJJ-MM-<symbol>-<kurz>  --  <Kurztitel>
- Status: offen | in-Pruefung | bestaetigt | verworfen (verbrannt bei HARKing)
- Mechanismus: Warum existiert der Edge? Wer verliert das Geld, das ich gewinnen
  will, und warum wiederholt er den Fehler?
- Instrument + Richtung: Markt, Zeitrahmen, erwartete Wirkrichtung.
- Vorhergesagtes Muster: Was MUSS im Ergebnis zu sehen sein, damit die These
  stuetzt? (Steht fest, bevor die Daten es bestaetigen duerfen.)
- Falsifikation: Was killt die These?
- backtests.csv-ids: (nach den Laeufen eintragen)
```

## Aktive Hypothesen

### H-2026-07-AUS200-mr  --  Oversold-Bounce (Mean-Reversion) auf dem Index
- Status: verworfen (15.07.2026, Baseline-Tor: zu wenige Signale ohne Korb-Pooling)
- Mechanismus: Kurzfristige Ueberverkauft-Rueckkehr. Nach scharfen Abverkaeufen
  kaufen systematische Rebalancer und Dip-Kaeufer den Index zurueck; die kurzfristige
  Ueberreaktion der Panikverkaeufer revertiert. Wer verliert: wer in die Schwaeche
  hinein verkauft (Stop-Kaskaden, Momentum-Aussteiger). Es ist DERSELBE Mechanismus,
  der auf Nasdaq-Einzelaktien den bisher einzigen z>2-Befund lieferte (Backtest 18,
  stock_mr RSI(2), z=2,46) -- Hypothese: er traegt auch auf dem Index AUS200.
- Instrument + Richtung: AUS200, D1, Long-only Oversold-Bounce (`stock_mr_v1`:
  RSI(2) tief, SMA(200)-Trendfilter, ATR-Stop). Trendfilter = nur Dips im
  Aufwaertstrend kaufen (kein fallendes Messer).
- Vorhergesagtes Muster: Da regime-abhaengig (Bull), Erwartung wie bei den Aktien:
  Fenster B (Bull) klar positiv (PF>1, z deutlich > 0), Fenster A (Bear 2022)
  neutral bis leicht negativ. Fuers Erfolgs-Tor (05) muss der gepoolte/robuste Edge
  ueber Walk-Forward halten; ein Bull-only-Edge ist als "Buy-the-Dip im Aufwaerts-
  trend" defensibel, aber muss ehrlich als regime-bedingt gekennzeichnet werden.
- Falsifikation: PF<1 auch in Fenster B (Bull); oder z in B nahe 0 (Rauschen);
  oder der Edge verschwindet, sobald der Trendfilter greift. Dann traegt der
  Aktien-Mechanismus NICHT auf den Index -> verwerfen.
- backtests.csv-ids: 166 (Fenster B); Fenster A = 0 Trades (Trendfilter blockte alle
  Longs im Baerenjahr 2022 -> keine CSV-Zeile, mechanismus-konsistent).
- **Baseline-Ergebnis (15.07.2026): verworfen.** Fenster B PF 0,25, z -2,12, nur
  8 Trades. Falsifikation erfuellt (PF<1 im Bull). **Strukturelle Kern-Einsicht:**
  der Aktien-MR-Edge (z=2,46, Backtest 18) entstand durch POOLING von ~500 Trades
  ueber einen 8-10-Titel-Korb. Ein EINZELNER Index liefert nur eine Handvoll
  Oversold-Signale (hier 8) -- kein Pooling, keine Querschnitts-Diversifikation,
  kein Edge. Der Mechanismus braucht den Aktien-KORB (Stufe 2), nicht den Index.
  -> AUS200 ist als Stufe-1-Sandkasten strukturell schwach fuer die einzige
  bewaehrte Edge-Quelle des Projekts.

### H-2026-07-AUS200-trend  --  Trend-Persistenz im Aktienindex
- Status: verworfen (15.07.2026, Baseline-Tor: EMA-Trend ohne Edge auf AUS200)
- Mechanismus: Aktienindizes zeigen Trend-Persistenz, weil Information langsam
  diffundiert und eine dauerhafte Long-Risikopraemie besteht. Trendfolger gewinnen
  das Geld, das Gegentrend-/Mean-Reversion-Haendler und zu frueh aussteigende Anleger
  systematisch verlieren -- ein wiederkehrender Verhaltensfehler, kein Einmaleffekt.
- Instrument + Richtung: AUS200 (einziger Index-CFD auf MetaQuotes-Demo, reale
  Ticks), Einstieg H1 mit H4-Bias, trendfolgend (EMA-Kreuz, `ema_mtf_v3`). Zunaechst
  long-lastig (Aufwaertstrend-Praemie); Short als Toggle offen.
- Vorhergesagtes Muster (steht VOR den Wertungslaeufen fest): ein trendfolgender
  Edge muss sich als PF > 1 in einem trendstarken Fenster zeigen und im
  Erfolgs-Tor (05) ueber Walk-Forward halten. Ein echter Mechanismus wirkt in BEIDEN
  Fenstern positiv (nicht nur im Bullenfenster).
- Falsifikation: kein PF > 1 in einem trendstarken Fenster; oder Edge nur in einem
  willkuerlichen Teilzeitraum ohne Trend-Regime-Bezug; oder WFE <= 0,5 im ersten OOS.
  Dann ist die Trend-Persistenz auf AUS200 nicht handelbar -> verwerfen.
- Vorbefund (Shakedown, KEIN Wertungslauf): AUS200 EMA-Trend, 2024-H1, PF 0,91
  (Verlust) -- ein erster Gegenwind, formal getestet wird ueber die Fenster A/B unten.
- backtests.csv-ids: 164 (Fenster A 2022-2023), 165 (Fenster B 2024-2026).
- **Baseline-Ergebnis (15.07.2026):** Fenster A PF 0,73 / z -1,42 (verliert);
  Fenster B PF 1,04 / z 0,21 (Rauschen). Das vorhergesagte Muster (PF>1 in einem
  trendstarken Fenster, in BEIDEN positiv) ist NICHT erfuellt -> Falsifikation
  greift am Baseline-Tor. Kein Signal, das eine Walk-Forward-Optimierung
  rechtfertigt (Abbruch-Treppe Stufe 0/1: nicht ueberoptimieren, was baseline
  schon z~0 zeigt). Empfehlung: EMA-Trend auf AUS200 verwerfen; naechste Hypothese
  mit anderem Mechanismus/Instrument. Endgueltiges Verwerfen nach Nutzer-Entscheid.

### H-STOCK-MR-BASELINE  --  Mean-Reversion RSI(2) auf US-Aktien-Korb (Baseline)
- Status: **verworfen** (15.07.2026, OOS-Kollaps: PF<1, WFE=-0,12)
- Mechanismus: Identisch mit dem einzigen z>2-Befund des Projekts (Backtest 18,
  z=2,46). Kurzfristige Ueberverkauft-Rueckkehr in starken Aufwaertstrends:
  Nach scharfen Abverkaeufen kaufen systematische Rebalancer und Dip-Kaeufer
  Einzelaktien zurueck; die kurzfristige Ueberreaktion der Panikverkaeufer
  (Stop-Kaskaden, Momentum-Aussteiger) revertiert innerhalb weniger Tage.
  Der Edge entsteht durch POOLING ueber einen diversifizierten Korb (10 Titel),
  was die Signaldichte auf ~80-100 Trades/2 Jahre hebt -- auf einem einzelnen
  Index (AUS200) war das Signal zu duenn (nur 8 Trades, verworfen).
- Instrument + Richtung: US-Aktien-Korb (AAPL, AMD, AMZN, AVGO, ADBE, ABNB,
  AXP, ABT, AIG, AEP), D1, Long-only. EA: `stock_mr_v1` mit Default-Parametern
  (RSI(2) Entry<10, Exit>80, SMA(200)-Trendfilter, 3xATR-Stop, MaxHold=5).
- Vorhergesagtes Muster: Gepoolter PF>1 und z>0 im IS (2023-2024); der Edge
  muss im OOS (2025) halten (WFE>0,5). Weil die Default-Parameter NICHT
  optimiert sind, ist dies ein reiner Mechanismus-Test -- haelt der Roheffekt
  auf einem neuen Korb unter dem neuen Protokoll? PF>1,4 waere Verdacht.
- Falsifikation: Gepoolter z<=0 im IS (kein Roheffekt); oder OOS-Kollaps
  (PF<1, WFE<=0,5); oder der Edge konzentriert sich auf <3 Symbole (kein
  echter Querschnitts-Effekt, sondern Einzeltitel-Glueck).
- backtests.csv-ids: 167-176 (IS), 177-185 (OOS)
- **IS-Ergebnis (15.07.2026):** 87 Trades gepoolt, 63,2% Wins, Netto +556 USD,
  PF 1,38, z=1,44. Positiv, aber nicht hochsignifikant. 6 von 10 Symbolen
  profitabel (breit gestreut, kein Einzeltitel-Glueck).
- **OOS-Ergebnis (15.07.2026):** 37 Trades gepoolt, 51,4% Wins, Netto -49 USD,
  PF 0,94, z=-0,17. **Vollstaendiger Kollaps.** WFE = z(OOS)/z(IS) = -0,12.
  Falsifikation greift doppelt: PF<1 UND WFE weit unter 0,5.
  Nur 3 von 9 aktiven Symbolen profitabel (AMD, AXP, ABT) -- der IS-Edge war
  breiter gestreut, was auf Regime-Abhaengigkeit hindeutet, nicht auf einen
  robusten Querschnitts-Mechanismus.
- **Strukturelle Erkenntnis:** Der alte z=2,46-Befund (Backtest 18) wurde auf
  einem ANDEREN Zeitraum und mit ANDERER Methodik (kein sauberes WF-Protokoll)
  erzielt. Unter dem neuen, strengen Protokoll (fixe IS/OOS-Trennung, ehrliches
  Pooling, Default-Parameter) traegt der RSI(2)-Oversold-Bounce-Mechanismus
  NICHT robust. Die Baseline-Ergebnisse im IS (z=1,44) waren moeglicherweise
  durch das Bullen-Regime 2023-2024 beguestigt. Optimierung an diesen
  Parametern ist laut Abbruch-Treppe (Stufe 2) NICHT gerechtfertigt.

## Kandidaten-Notizen (Mechanismus fehlt noch)

<!-- Data-Mining-/Screening-Treffer ohne Mechanismus. Kein Testbudget, bis ein
     plausibler Mechanismus gefunden ist. -->
