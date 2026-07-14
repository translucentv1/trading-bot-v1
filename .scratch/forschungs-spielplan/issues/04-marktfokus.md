# 04 -- Marktfokus: Nasdaq-Stocks-Pivot bestaetigen oder oeffnen

Type: grilling
Status: resolved
Blocked by: 01

## Question

Auf welchen Markt/Instrumentenkorb konzentriert sich die naechste Forschungsrunde
verbindlich?
- Nasdaq-Einzelaktien (der juengste Pivot) bestaetigen -- oder bewusst wieder
  oeffnen (Indizes, ETFs, zurueck zu FX/Gold mit besserer Methodik)?
- Falls Einzelaktien: welches Universe (Liquiditaet, Anzahl Symbole, Sektoren)?
- Entscheidungskriterium: wo ist die Datenlage (Ticket 01) gut genug UND ein
  plausibler Mechanismus fuer einen Edge vorhanden?

Blockiert von 01 (Datenlage), weil die Marktwahl an der real verfuegbaren Historie
und den Kosten haengt.

## Answer

Gestaffelter Marktfokus statt entweder/oder. Grundlogik: Die 121 Nullnummern lagen
an der Methodik (Ticket 02/05), nicht am Markt -- ein blosser Marktwechsel repariert
nichts. Also erst die neue Methodik auf sauberen Daten validieren, dann verbreitern.

### Stufe 1 (jetzt): US100/NAS100 (Index) als Validierungs-Sandkasten
- Primaerfokus ist der Nasdaq-100-Index-CFD (US100/NAS100) -- laut Ticket 01 die
  einzige Quelle mit tiefer, sauberer, liquider Historie in MT5.
- Zweck: das Protokoll aus Ticket 05 erst auf vertrauenswuerdigen Daten haerten,
  ohne dass Datenmuell (Split/Dividenden/Luecken der Einzelaktien) die Ergebnisse
  vergiftet. Ziel der Phase ist METHODIK-Haertung, nicht zwingend ein Index-Edge.

### Stufe 2 (Phase-4b, spaeter): Einzelaktien-Korb
- Der eigentlich andere Edge (Querschnitt vieler Titel, relative Staerke/
  Mean-Reversion, viele halb-unabhaengige Beobachtungen) liegt bei Einzelaktien.
- Wird als eigenes Folge-Vorhaben aufgesetzt, NICHT jetzt.

### Uebergangs-Trigger Stufe 1 -> Stufe 2
Phase-4b wird freigeschaltet, sobald BEIDES gilt:
1. Das Protokoll aus 05 ist mindestens einmal vollstaendig end-to-end durchlaufen
   -- egal mit welchem Ausgang: entweder eine Index-Strategie hat das komplette
   Erfolgs-Tor bestanden, ODER die Abbruch-Treppe hat mindestens eine Idee ehrlich
   verworfen (Beweis, dass das Protokoll auch "nein" sagt). "Erst ein echter
   Index-Edge" ist NICHT Bedingung -- sonst Gefahr des ewigen Sandkastens.
2. Broker-/Symbol-Datencheck bestanden (Historientiefe je Fenster A/B, Split-
   Pruefung der Zielsymbole) -- die harte Voraussetzung aus Ticket 01.

### Ausgeschlossen
- FX/Gold wird nicht wiederaufgenommen, ausser eine konkrete Strategie-Idee
  verlangt es ausdruecklich.

### Offen gelassen (Detail, keine Marktfokus-Entscheidung)
- Exaktes Broker-Symbol fuer US100/NAS100 und Test-Timeframe(s) -- gehoert zur
  konkreten Strategie/zum Setup, nicht zur Marktfokus-Frage.
