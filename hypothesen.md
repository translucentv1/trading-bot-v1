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

<!-- Noch keine. Erste Hypothese entsteht mit dem ersten US100-Zyklus des neuen
     Prozesses (Spielplan Abschnitt 8, Folge-Vorhaben 4). -->

## Kandidaten-Notizen (Mechanismus fehlt noch)

<!-- Data-Mining-/Screening-Treffer ohne Mechanismus. Kein Testbudget, bis ein
     plausibler Mechanismus gefunden ist. -->
