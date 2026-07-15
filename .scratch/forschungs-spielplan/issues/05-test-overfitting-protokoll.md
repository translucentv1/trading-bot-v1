# 05 -- Verbindliches Test- & Overfitting-Protokoll (KERNTICKET)

Type: grilling
Status: resolved
Blocked by: 02

## Question

Welches verbindliche Protokoll muss jede kuenftige Strategie durchlaufen, damit
ein Ergebnis als "echter Edge" und nicht als Overfitting gilt?
- OOS-Fenster: Definition A/B beibehalten oder Walk-Forward einfuehren?
- Pooling-Methodik: wie wird der gepoolte |z|-Wert korrekt und ehrlich gebildet?
- Multiple-Testing-Buchfuehrung: wie werden die bereits 121+ Laeufe (und jeder
  neue) gezaehlt und bestraft (Bonferroni/Deflated Sharpe/PBO)?
- Parameter-Sparsamkeit: Obergrenze fuer freie Parameter? Robustheits-Check Pflicht?
- Erfolgs-/Abbruch-Kriterium: konkrete Schwellen (z. B. PF 1,1-1,4 ueber beide
  Fenster, |z| > 2 nach Multiple-Testing-Korrektur) -- was genau, ab wann Abbruch?

Blockiert von 02 (Methoden-Recherche). Dies ist der zentrale Hebel der Karte --
das Protokoll graduiert danach mehrere Nebel-Punkte (Hypothesen-Pipeline,
Repo-Struktur).

## Answer

Verbindliches Test- & Overfitting-Protokoll. Jede kuenftige Strategie durchlaeuft
es; besteht sie nicht ALLE Pflichtpunkte, geht sie nicht nach Demo-Paper.
Grundsatz: Prozess-Schutz VOR Statistik; ohne ehrliches N ist jede Korrektur
wertlos. Basis: Ticket 02 (Pflicht-Minimum = Walk-Forward + Robustheit + DSR).

### 1. Rueckgrat -- dreistufiges Pflicht-Minimum
1. Walk-Forward mit versiegeltem OOS-Fenster (nativ im MT5-Forward-Modus).
2. Robustheits-Heatmap + Parameter-Sparsamkeit (faellt bei MT5-Optimierung ab).
3. Deflated Sharpe Ratio mit ehrlichem N aus backtests.csv.
Alle drei sind Pflicht. Die alten Fenster A/B laufen als zwei WF-Zyklen weiter,
verlieren aber ihren Sonderstatus als Haupturteil.

### 2. Walk-Forward -- konkrete Werte
- Rolling Walk-Forward (gleich langes IS-Fenster wandert; reagiert auf Regime).
- IS:OOS = 3:1 (75/25).
- Mindestens 5 WF-Zyklen.
- Walk-Forward-Efficiency (OOS-Perf / IS-Perf) > 0,5 als Pflicht-Schwelle.
- Mindestens 30 Trades pro freiem Parameter im IS-Fenster.
- Lockbox = juengstes Datenstueck (oder zweites Symbol), waehrend der gesamten
  Entwicklung nie angefasst; erst ganz am Ende ein einziger Blick.

### 3. Parameter-Sparsamkeit & Robustheit
- Obergrenze: max. 4 freie Parameter (mehr nur mit expliziter Begruendung).
- Plateau-Pflicht: gewaehlter Parametersatz muss auf glattem Plateau liegen --
  direkte Nachbarn in der Heatmap innerhalb ~20 % der Kennzahl. Scharfe
  Einzelspitze wird verworfen.
- Zappel-Warnung: springt das Optimum ueber die WF-Zyklen stark (12->47->23),
  gilt die Strategie als overfit und faellt durch.

### 4. Deflated Sharpe & ehrliches N
- N = Anzahl backtests.csv-Zeilen derselben Strategie-Idee/Familie (verwandte
  Laeufe zaehlen voll). N startet pro Familie neu, nicht projektweit bei 1.
- Ehrlichkeits-Regel (Anti-HARKing): VOR jedem Lauf die Hypothese notieren --
  neue Spalte `hypothese` in backtests.csv. Kein nachtraegliches Umdeuten.
- DSR-Schwelle: Wahrscheinlichkeit > 0,95, dass die wahre Sharpe > 0 ist (nach
  Bestrafung fuer N). Vorab-Check: naive Signifikanz mit N multiplizieren
  (Bonferroni-artig); faellt das durch, DSR gar nicht erst rechnen.
- Umsetzung: wenige Zeilen Python in tools/ (analog validate_backtests.py), N aus
  backtests.csv, DSR rechnen. Bau = Folge-Arbeit; hier nur Regel + Schwelle.

### 5. Zusammengesetztes Erfolgs-Kriterium (alle Pflicht fuer Demo-Paper)
1. WFE > 0,5 ueber >= 5 Rolling-WF-Zyklen.
2. Robustheit: glattes Plateau, kein Zappeln, <= 4 Parameter, >= 30 Trades/Param.
3. Deflated Sharpe > 0,95 mit ehrlichem N.
4. Profit Factor im Korridor 1,1-1,4 ueber die OOS-Zyklen. PF > 1,4 ist KEIN
   Feiergrund, sondern Overfit-/Zu-wenig-Trades-Verdacht, der zu pruefen ist.
5. Lockbox einmal ganz am Ende; grobe Groessenordnung muss halten (kein Kollaps).

### 6. Abbruch-Treppe (fail fast, fail cheap -- billigste Checks killen zuerst)
- Stufe 0 (vor jeder Optimierung): erzeugt die Idee im IS-Fenster >= 30
  Trades/Param? Wenn nein -> sofort raus.
- Stufe 1 (nach dem ersten WF-Zyklus): scharfe Spitze statt Plateau -> sofort
  raus, restliche Zyklen nicht laufen lassen.
- Stufe 2 (erster OOS-Blick): WFE <= 0,5 oder PF < 1,0 -> raus. PF > 1,4 ->
  anhalten und pruefen.
- Stufe 3 (nach >= 5 Zyklen): zappelnde Optima -> raus.
- Stufe 4 (Statistik): DSR <= 0,95 -> raus.
- Stufe 5 (Lockbox, einmal am Ende): Kollaps -> raus.
- HARKing-Budget: max. ~15 Laeufe pro Strategie-Familie ohne bestandene
  Stufe 1-2 -> Familie zu den Akten (Fazit in backtests.csv).

### Folgen fuer andere Tickets / Nebel
- Ticket 06 (Promotion-Gate) ist entblockt: die Demo-Paper-Schwellen sind exakt
  das zusammengesetzte Kriterium aus Abschnitt 5.
- Neue backtests.csv-Spalte `hypothese` noetig (kleine Repo-Aenderung, Folge-Arbeit).
- DSR/Validate-Python-Pipeline in tools/ = Folge-Vorhaben (planen, nicht bauen).
- KONTEXT.md-Glossar sollte die neuen Begriffe aufnehmen (Walk-Forward, WFE,
  Lockbox, Deflated Sharpe, HARKing-Budget) -- via /domain-modeling, separat.
