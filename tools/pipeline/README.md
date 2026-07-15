# Backtest-Pipeline (tools/pipeline/)

Automatisierter End-to-End-Backtest-Loop aus dem Spielplan (Ticket 08).
Ein Kommando: **kompilieren -> .ini erzeugen -> Tester-Lauf -> Report parsen ->
Zeile an `backtests.csv` -> `validate_backtests.py`.**

Endet strikt vor Live -- nur Backtest/Optimierung wird automatisiert (Eiserne Regel).

## Dateien

| Datei | Rolle |
|---|---|
| `config.json` | **Die eine Datei, die DU ausfuellst** (MT5-Pfade auf diesem Rechner). |
| `backtest.ini.template` | Vorlage fuer die Tester-Konfiguration (Platzhalter). |
| `run_backtest.ps1` | Orchestrator (PowerShell): steuert Compile, Lauf, Parsing. |
| `parse_report.py` | Liest den MT5-Report, haengt EINE Zeile an `backtests.csv` an. |

## Einmal einrichten

1. **`config.json` ausfuellen** -- drei Pfade:
   - `terminal_exe` -> `terminal64.exe`
   - `metaeditor_exe` -> `metaeditor64.exe`
   - `mql5_dir` -> der `MQL5`-Ordner der Terminal-Instanz
     (MT5 -> Datei -> **Datenordner oeffnen**; dort liegt `MQL5`).
   Die restlichen Werte sind Spielplan-Vorgaben (Model=4 reale Ticks, Deposit,
   Kosten je Instrument) -- nur mit Grund aendern.
2. Python muss verfuegbar sein (wie fuer `validate_backtests.py`).

## Aufruf (Beispiel: US100, In-Sample-Fenster, WF-Zyklus 1)

```powershell
pwsh tools/pipeline/run_backtest.ps1 `
  -Symbol US100 -FromDate 2022.01.01 -ToDate 2023.12.31 `
  -Expert ema_mtf_v3.mq5 -Period H1 `
  -Phase wf-is -WfZyklus 1 -Hypothese H-2026-07-US100-ovngap `
  -Strategie ema-cross -Richtung long -ExecTf H1 -BiasTf H4
```

Wichtige Parameter:
- `-ForwardMode` steuert das versiegelte OOS (Walk-Forward, Ticket 05):
  `0` kein Forward | `1` 1/2 | `2` 1/3 | `3` 1/4 | `4` eigenes Datum (`-ForwardDate`).
- `-Phase` traegt die Lauf-Rolle in die CSV: `sieben` / `wf-is` / `wf-oos` /
  `lockbox` / `stress` -- damit trennbar ist, was ins Erfolgs-Tor zaehlt (Ticket 07:
  Vorab-Sieb-Laeufe nie werten).
- `-Hypothese` = der Key aus `hypothesen.md` (Pflicht fuer Wertungslaeufe, Ticket 09).

## Robustheit (Ticket 08)

- **Compile-Check:** metaeditor-Log wird auf Fehler geparst; >0 errors -> Abbruch.
- **Report-Plausibilitaet:** kein Report / keine Trades -> **KEINE** CSV-Zeile,
  lauter Abbruch ("Demo-Server/Daten pruefen").
- **Retry:** begrenzte Wiederholung (`max_retries` in config.json), dann Stopp.
- **Atomar:** `parse_report.py` schreibt erst `.tmp`, dann `replace` -- nie halbe CSV.

## Gegen echten Lauf verifiziert (15.07.2026, AUS200)

Beide anfaenglichen Baustellen sind an einem echten Tester-Lauf geschlossen:

1. **Report-Fundort:** MT5 legt den Report im Datenordner-Root ab
   (`...\Terminal\<hash>\<name>.htm`). Der Block `REPORT SUCHEN` in
   `run_backtest.ps1` findet ihn dort automatisch.
2. **Kodierung + Labels:** der deutsche MT5-Report ist **UTF-16**; `parse_report.py`
   erkennt das BOM automatisch, normalisiert Umlaute und nutzt die deutschen Labels
   (`LABELS`). Alle 9 Kennzahlen wurden korrekt extrahiert (net, PF, Sharpe, DD%,
   Trades, Winrate, avg_win, avg_loss, Verlustserie).

Falls du MT5 auf **Englisch** stellst oder eine andere Version nutzt, ist `LABELS`
weiterhin die eine Stelle zum Nachziehen (EN-Varianten sind bereits hinterlegt).

**Robustere Zukunft (empfohlene Haertung):** statt HTML zu parsen, die Kennzahlen
im EA per `OnTester()` in eine strukturierte Datei (JSON/CSV-Zeile) schreiben und
die hier lesen. Das entfaellt jedes Scraping-Risiko. Bewusst als naechster
Ausbauschritt notiert, nicht in diesem ersten Wurf.

## Ablage

- Roh-Reports + generierte `.ini` landen in `reports/` (gitignored).
- Verdichtete Heatmap-Belege eines Schluessellaufs kommen versioniert nach
  `reports/heatmaps/` (Ticket 10).
