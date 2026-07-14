# 02 -- Overfitting-Schutz-Methoden fuers Solo/MT5-Setup

Type: research
Status: resolved
Blocked by: -

## Question

Welche etablierten Methoden gegen Overfitting im systematischen Trading passen zu
einem Solo-Setup mit MT5-Strategy-Tester (begrenzte Rechenleistung, kein
Cloud-Cluster)? Bewerte fuer jede: Was misst sie, wie aufwaendig, wie in MT5
umsetzbar.
- Walk-Forward-Analyse (rolling / anchored)
- Out-of-Sample-Fenster (bereits genutzt: Fenster A/B) -- Best Practices
- Probability of Backtest Overfitting (PBO / CSCV, Bailey/Lopez de Prado)
- Deflated Sharpe Ratio, Minimum Backtest Length
- White's Reality Check / Hansen SPA (Multiple-Testing-Korrektur)
- Parameter-Sparsamkeit / Robustheits-Heatmaps
- Wie man 121+ bereits gelaufene Tests als "Multiple Testing" buchfuehrt und bestraft

Ergebnis speist Ticket 05 (verbindliches Test- & Overfitting-Protokoll) -- das
Kernticket der Karte.

## Answer

Einordnung fuers Solo-Setup: Methoden teilen sich in zwei Klassen.
(A) Prozess-Methoden, die *waehrend* des Testens vor Ueberanpassung schuetzen
(Walk-Forward, OOS-Fenster, Parameter-Sparsamkeit). (B) Statistische
Korrekturen, die *nachtraeglich* fragen "war das gefundene Ergebnis nur Glueck
aus vielen Versuchen?" (PBO/CSCV, Deflated Sharpe, Reality Check/SPA). Ein
Anfaenger-Solo-Setup braucht mindestens je eine aus beiden Klassen.

### 1. Walk-Forward-Analyse (rolling / anchored)
- Misst: Ob Parameter, die auf einem In-Sample-Fenster optimiert wurden, im
  direkt folgenden, nie gesehenen Out-of-Sample-Fenster halten. Ueber mehrere
  rollende Fenster hinweg -> Robustheit ueber Zeit/Regime.
- Aufwand: Mittel. Konzeptionell simpel, aber viele Optimierungslaeufe.
  Rolling = gleich langes IS-Fenster wandert (gut fuer kurzfristige Strategien,
  reagiert auf Regimewechsel). Anchored = IS-Startpunkt fix, Fenster waechst
  (stabiler, gut fuer langfristige Strategien).
- MT5-Umsetzung: Nativ eingebaut. Strategy Tester hat "Forward"-Modus
  (Einstellung Forward = 1/4, 1/3, 1/2 teilt die Periode automatisch in IS und
  vorwaerts-OOS). Fuer echtes mehrfaches Rolling: mehrere Testperioden manuell
  hintereinander laufen lassen oder per Python-Skript die Tester-Aufrufe
  scripten. Faustregeln aus der Literatur: IS:OOS ca. 3:1 (75/25),
  mind. ~30 Trades pro freiem Parameter im IS-Fenster, mind. 5 WF-Zyklen,
  Walk-Forward-Efficiency (OOS-Perf / IS-Perf) > 0.5 als grobes Guetesignal.

### 2. Out-of-Sample-Fenster -- Best Practices
- Misst: Generalisierung auf Daten, die bei der Entscheidung NICHT beruehrt
  wurden. Nur wertvoll, solange das OOS-Fenster wirklich unberuehrt bleibt.
- Aufwand: Gering -- aber Disziplin ist alles.
- Best Practices: (a) OOS-Fenster VOR dem ersten Blick festlegen und
  "versiegeln". (b) Jeder erneute Blick aufs OOS-Fenster verbraucht es -- nach
  wenigen Iterationen ist es de facto In-Sample geworden (das ist genau die
  Falle bei den bisherigen Fenstern A/B). (c) Ideal ein finales "Lockbox"-Set
  (juengste Daten oder ein anderes Symbol/Instrument), das erst ganz am Ende
  EINMAL angefasst wird. (d) Regimevielfalt beachten: OOS sollte andere
  Marktphasen enthalten als IS. MT5: einfach zwei getrennte Datumsbereiche im
  Tester; Live-Demo-Paper-Trading ist das ehrlichste OOS.

### 3. Probability of Backtest Overfitting (PBO / CSCV)
- Misst: Wahrscheinlichkeit, dass die im Backtest beste Konfiguration im OOS
  UNTERdurchschnittlich abschneidet -- also dass die Auswahl reines Overfitting
  war. Ausgabe: eine Zahl 0..1 (PBO). Hoch = Auswahl war Glueck.
- Aufwand: Mittel-hoch (Python). CSCV zerlegt die Renditematrix aller
  N Konfigurationen in S Bloecke, bildet alle Kombinationen von IS/OOS-Haelften
  und zaehlt, wie oft der IS-Sieger im OOS unter den Median faellt. Braucht die
  Trade-/Rendite-Zeitreihe JEDER getesteten Konfiguration, nicht nur die
  Endkennzahl.
- MT5-Umsetzung: MT5 liefert das nicht selbst. Man exportiert pro
  Optimierungslauf die Perioden-Renditen (z.B. Backtest-Report -> CSV/XML) und
  rechnet PBO in Python. Genau der richtige Rahmen fuer "121+ gelaufene Tests":
  jede Zeile in backtests.csv ist eine Konfiguration.

### 4. Deflated Sharpe Ratio (DSR) & Minimum Backtest Length (MinBTL)
- Misst: DSR korrigiert eine Sharpe Ratio nach unten fuer (a) Anzahl der
  Versuche N, (b) Varianz der Sharpe-Werte ueber die Versuche, (c) Schiefe und
  Kurtosis der Renditen, (d) Sample-Laenge. Ausgabe: Wahrscheinlichkeit, dass
  die wahre Sharpe > 0 ist, nachdem man fuers Herumprobieren bestraft hat.
  MinBTL sagt umgekehrt: bei N Versuchen, wie viele Jahre Daten braucht man
  mindestens, damit eine Sharpe von 1 nicht schon durch Zufall entsteht.
- Aufwand: Gering-mittel. Geschlossene Formeln, wenige Zeilen Python. Der
  wichtigste Input ist ehrliches N (Zahl der Versuche) -- hier direkt mit dem
  121+-Problem verzahnt.
- MT5-Umsetzung: Reine Nachrechnung ausserhalb MT5. Braucht nur die
  Sharpe-Werte / Renditereihen aus den Reports + ein ehrliches N. Sehr guter
  Aufwand/Nutzen fuer ein Solo-Setup.

### 5. White's Reality Check (RC) / Hansen SPA
- Misst: Ob die BESTE aus vielen Strategien/Parametersaetzen einen echten Edge
  ueber einer Benchmark hat, oder ob so ein Spitzenwert bei so vielen Versuchen
  allein durch Zufall zu erwarten war. Nutzt Bootstrap ueber die
  Rendite-Zeitreihen aller Kandidaten. Hansen SPA = verbesserte, weniger
  konservative Variante (weniger anfaellig fuer viele schlechte Kandidaten).
- Aufwand: Hoch. Stationaerer Bootstrap ueber die volle Renditematrix aller
  Kandidaten; korrekte Implementierung ist fehleranfaellig.
- MT5-Umsetzung: Nur Python, nicht in MT5. Fuer einen Anfaenger eher
  Kuer als Pflicht -- DSR liefert eine aehnliche Multiple-Testing-Korrektur
  mit deutlich weniger Aufwand. RC/SPA als spaeteres Upgrade vormerken.

### 6. Parameter-Sparsamkeit & Robustheits-Heatmaps
- Misst: Ob die Performance auf einem PLATEAU liegt (Nachbarparameter fast
  gleich gut = robust) oder auf einer scharfen Spitze (nur exakt dieser Wert
  gut = overfit). Weniger freie Parameter = geringere Overfitting-Kapazitaet.
- Aufwand: Gering. Faellt bei jeder Gitter-Optimierung praktisch gratis ab.
- MT5-Umsetzung: MT5 Strategy Tester Optimierung liefert genau das: 2D-Ergebnis
  ueber zwei Parameter -> als Heatmap anschaubar (im Optimierungsergebnis-Tab
  oder CSV-Export -> Python/Excel-Heatmap). Regel: Parameterzahl klein halten,
  glatte Plateaus bevorzugen, zappelnde Optima (Wert springt 12->47->23 ueber
  WF-Zyklen) als Overfitting-Warnung werten. Bester Aufwand/Nutzen ueberhaupt.

### 7. Buchfuehrung der 121+ Tests als Multiple Testing
- Kernproblem: Jeder der bisher gelaufenen Tests ist ein "Versuch". Je mehr
  Versuche, desto sicherer entsteht ein glaenzender Backtest rein zufaellig.
  Wenn N (Versuchszahl) nicht ehrlich mitgezaehlt wird, sind alle
  Signifikanz-Aussagen wertlos.
- Umsetzung: (a) backtests.csv ist bereits das Versuchsregister -- jede Zeile =
  ein Versuch; N wird damit einfach die Zeilenzahl (hier 121+). Verwandte
  Laeufe (gleiche Idee, nur andere Parameter) zaehlen voll mit. (b) N als
  direkten Input in Deflated Sharpe / MinBTL geben -> automatische Bestrafung.
  (c) Faustregel-Schaerfung: naive Signifikanzschwelle mit N multiplizieren
  (Bonferroni-artig) als schnelle Orientierung, bevor man DSR sauber rechnet.
  (d) Ehrlichkeitsregel ins Protokoll: kuenftig VOR jedem Lauf die Hypothese
  notieren, damit N nicht heimlich weiterwaechst ("HARKing" vermeiden).

### Priorisierte Empfehlung -- Pflicht-Minimum fuer Ticket 05

Nach Aufwand/Nutzen fuer einen Anfaenger im Solo-MT5-Setup:

1. PFLICHT -- Walk-Forward mit versiegeltem OOS-Fenster (Methode 1+2). Nativ in
   MT5 (Forward-Modus), schuetzt strukturell, kein Python noetig. Das ist die
   Basis-Hygiene.
2. PFLICHT -- Robustheits-Heatmap + Parameter-Sparsamkeit (Methode 6). Faellt
   bei jeder MT5-Optimierung gratis ab, sofort verstaendlich, filtert die
   scharfen Overfit-Spitzen raus.
3. PFLICHT -- Deflated Sharpe Ratio mit ehrlichem N aus backtests.csv
   (Methode 4+7). Wenige Zeilen Python, bestraft die 121+ Versuche direkt und
   quantifiziert. Das ist die statistische Mindest-Korrektur.

KUER / spaeteres Upgrade (wenn Python-Pipeline steht): PBO/CSCV (Methode 3) als
tieferer Overfitting-Check, danach White RC / Hansen SPA (Methode 5). Beide
brauchen die volle Renditematrix aller Konfigurationen und sind aufwaendiger --
nicht Teil des Pflicht-Minimums.

Merksatz fuers Protokoll: Prozess-Schutz (WF+OOS+Sparsamkeit) VOR statistischer
Korrektur (DSR). Ohne ehrliches N ist jede Statistik wertlos.

### Quellen
- Bailey, Borwein, Lopez de Prado, Zhu -- The Probability of Backtest
  Overfitting (PBO/CSCV): https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2326253
  und PDF: https://www.davidhbailey.com/dhbpapers/backtest-prob.pdf
- Bailey & Lopez de Prado -- The Deflated Sharpe Ratio (Selection Bias, MinBTL):
  https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2460551
  und PDF: https://www.davidhbailey.com/dhbpapers/deflated-sharpe.pdf
- Deflated Sharpe Ratio -- Uebersicht: https://en.wikipedia.org/wiki/Deflated_Sharpe_ratio
- Jansen -- Minimum Backtest Length & Deflated SR (praktische Umsetzung,
  ML4Trading): https://stefan-jansen.github.io/machine-learning-for-trading/08_ml4t_workflow/01_multiple_testing/
- White (2000) A Reality Check for Data Snooping:
  https://www.researchgate.net/publication/4896389_A_Reality_Check_for_Data_Snooping
- Hsu, Hsu, Kuan -- Re-Examining Technical Analysis mit Reality Check & Hansen
  SPA (Step-SPA): https://homepage.ntu.edu.tw/~ckuan/pdf/Step-SPA-20090720.pdf
- Walk-Forward anchored vs rolling, Best Practices (QuantInsti):
  https://blog.quantinsti.com/walk-forward-optimization-introduction/
- Walk-Forward-Optimierung Backtesting-Guide (Ratios/WFE):
  https://backtrex.com/en/blog/walk-forward-optimization-backtesting-guide
