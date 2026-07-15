# 09 -- Systematische Hypothesen-Pipeline: woher kommen Strategie-Ideen?

Type: grilling
Status: resolved
Blocked by: -

## Question

Nach welchem systematischen Prozess entstehen kuenftig Strategie-Hypothesen -- statt
zufaelligem Herumprobieren (das mit zu 121+ Nullnummern beigetragen hat)?
- Quellen: oekonomischer Mechanismus zuerst (warum sollte ein Edge existieren?) vs.
  Data-Mining/Screening. Wie wird ein plausibler Mechanismus verlangt, BEVOR
  getestet wird?
- Format: wie wird eine Hypothese notiert (passt zur neuen Spalte `hypothese` aus
  Ticket 05, Anti-HARKing)?
- Priorisierung: nach welchem Kriterium wird entschieden, welche Idee als Naechstes
  getestet wird?
- Passung zum Marktfokus (Ticket 04): auf dem Index (Stufe 1) andere Ideenklasse
  (Trend/Mean-Reversion eines Instruments) als bei Einzelaktien (Querschnitt/
  relative Staerke, Stufe 2) -- die Pipeline muss beide Phasen bedienen.

Graduiert aus dem Nebel nach Aufloesung von 04 + 05 (Marktfokus + Protokoll stehen,
also ist "wie kommen Ideen rein" jetzt scharf formulierbar). Frontier: startklar.

## Answer

Ideen entstehen kuenftig nach einem disziplinierten Prozess mit hartem Eingangstor,
festem Format, klarer Priorisierung und stufenweiser Marktbindung -- der billigste
Filter (ein Satz Nachdenken) ersetzt teure Fehl-Backtests. Direkter Hebel gegen die
Kern-These (Overfitting/Methodik statt Markt).

### 1. Eingangstor: oekonomischer Mechanismus zuerst (Pflicht)
Vor JEDEM Lauf muss die Hypothese in einem Satz beantworten: Warum existiert dieser
Edge -- wer verliert das Geld, das ich gewinnen will, und warum macht er den Fehler
wiederholt? Kein plausibler Mechanismus -> kein Backtest. Der Mechanismus muss auf
eine bekannte Marktstruktur-Ursache zeigen (Overnight-Risikopraemie, Momentum durch
verzoegerte Info-Verarbeitung, Mean-Reversion durch Liquiditaets-Ueberschiessen,
Kalender-/Auktionseffekte) -- nicht "Indikator sah gut aus". Data-Mining/Screening
ist nicht verboten, aber degradiert: ein Treffer ohne Mechanismus ist nur eine
Kandidaten-Notiz, kein Testkandidat, bis er einen Mechanismus findet.

### 2. Format: 4 Felder, vor dem Lauf festgeschrieben, danach unveraenderlich
Jede Hypothese haelt fest:
1. Mechanismus -- der eine Satz aus Tor 1.
2. Instrument + Richtung -- Markt, Zeitrahmen, erwartete Wirkrichtung.
3. Vorhergesagtes Muster -- was im Ergebnis zu sehen sein MUSS, damit die These
   stuetzt (Anti-HARKing-Kern: Vorhersage steht vor den Daten).
4. Falsifikation -- was die These killt.
In backtests.csv steht ein kurzer Hypothese-Key (z.B. H-2026-07-US100-ovngap), der
auf einen ausfuehrlichen Eintrag in einer eigenen hypothesen.md zeigt (CSV-Header
bleibt schlank). Unveraenderlich nach dem ersten Lauf: wird das vorhergesagte Muster
nachtraeglich an die Daten angepasst, ist das HARKing -> Hypothese verbrannt.

### 3. Priorisierung: staerkster Mechanismus x billigste Widerlegung
Reihung nach (a) Mechanismus-Staerke (dokumentierte Praemie schlaegt selbst-
ausgedachte Psychologie) und (b) Widerlegungs-Kosten (was das Vorab-Sieben Stufe 0
billig killt, kommt zuerst). Explizit NICHT nach vermuteter Gewinnhoehe -- genau das
fuehrte in Scheingewinne (Erwartung vor Trefferquote). Koppelt ans HARKing-Budget
aus 05 (~15 Laeufe/Familie): schwache Mechanismen bekommen das Budget gar nicht
erst. Kurz: Wahrheit vor Gewinn.

### 4. Marktbindung: Ideen-Klasse folgt der Stufe (Ticket 04)
- Stufe 1 (Index US100, jetzt): nur Einzelinstrument-Mechanismen (Trend/Momentum,
  Mean-Reversion, Kalender-/Auktions-, Overnight-Gap). Saubere Sandbox fuer 05.
- Stufe 2 (Einzelaktien, Phase-4b): Querschnitts-Mechanismen (relative Staerke,
  Cross-Sectional-Momentum, Paar-/Korb-Effekte) -- vorher nur geparkte Kandidaten-
  Notizen, kein Testbudget.
- Gemeinsames 4-Feld-Format + gleiche Priorisierung; nur der Ideen-Pool oeffnet sich
  am selben Uebergangs-Trigger wie 04 (Protokoll einmal end-to-end + Datencheck).

### Verankerung
- Fuellt die Spalte `hypothese` aus Ticket 05 mit echtem Anti-HARKing-Gehalt.
- Neue Datei hypothesen.md als Register (Repo-Struktur -> Ticket 10 verankert sie).
- Marktstufen + Trigger konsistent mit Ticket 04.
