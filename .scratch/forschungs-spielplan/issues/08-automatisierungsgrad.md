# 08 -- Automatisierungsgrad des Backtest-Laufs festlegen

Type: grilling
Status: resolved
Blocked by: 03

## Question

Welchen Automatisierungsgrad schreibt der Spielplan fuer den Backtest-Lauf fest?
Ticket 03 hat gezeigt: headless-CLI ist machbar (terminal64.exe /config, XML-Report,
Sweeps, metaeditor64.exe /compile). Zu entscheiden:
- Wie weit soll automatisiert werden: nur Einzellaeufe, oder voller Loop
  (kompilieren -> .ini generieren -> Lauf -> XML parsen -> backtests.csv anhaengen
  -> validate_backtests.py)?
- Sprache/Ort der Automatisierung: PowerShell, Python (tools/), oder Mischung?
- Wie wird mit Demo-Server-Aussetzern umgegangen (Retry, manueller Fallback)?
- Verhaeltnis zur Eisernen Regel "Live nur manuell": Automatisierung endet strikt
  vor Live -- nur Backtest/Optimierung wird automatisiert.
- Ist der Bau dieser Pipeline Teil dieser Karte (task) oder Folge-Vorhaben?
  (Scope-Regel der Karte: planen, nicht bauen -- hier nur den Zielgrad entscheiden.)

Graduiert aus dem Nebel nach Aufloesung von 03. Frontier: 03 ist resolved,
also startklar.

## Answer

Zielgrad: voller End-to-End-Loop, robust, PowerShell + Python, Bau als vorrangiges
Folge-Vorhaben. Die Karte legt den Grad fest, baut die Pipeline nicht selbst.

### 1. Umfang: voller End-to-End-Loop (ein Kommando)
`run_backtest` erledigt in einem Rutsch:
1. aktiven EA kompilieren (Compile-Log auf "0 errors" pruefen),
2. .ini aus Vorlage generieren (Symbol, Zeitraum, Inputs, Forward-Modus fuer WF),
3. Tester-Lauf starten und warten (Start-Process -Wait, ShutdownTerminal=1),
4. XML-Report parsen, Kennzahlen als Zeile an backtests.csv anhaengen,
5. tools/validate_backtests.py anstossen.
Grund: Protokoll 05 verlangt viele Laeufe (>=5 WF-Zyklen, Sweeps, DSR ueber N) --
halb-manuell waere die Disziplin-Bremse, die schon vorher gescheitert ist.

### 2. Grenze zu Live (Eiserne Regel)
Automatisierung endet strikt vor Live -- nur Backtest/Optimierung wird
automatisiert, nie die Live-Ausfuehrung.

### 3. Sprache/Ort
- PowerShell als Orchestrator (startet metaeditor64.exe/terminal64.exe, wartet,
  prueft Compile-Log) -- Windows-nativer Prozess-Kram.
- Python fuer Auswertung (XML parsen, backtests.csv schreiben) -- konsistent mit
  vorhandenem tools/validate_backtests.py, tools/pool_backtests.py.
- Ort: tools/ -- z.B. tools/run_backtest.ps1 + tools/parse_report.py + .ini-Vorlage.

### 4. Robustheit gegen Demo-Server-Aussetzer ("laut abbrechen statt Muell schreiben")
- Report-Plausibilitaetscheck: enthaelt der XML-Report ueberhaupt Trades/Daten?
  Leer/kaputt -> KEINE CSV-Zeile, sondern Fehler melden.
- Begrenzter Retry (2-3x mit kurzer Pause) bei Verbindungs-/Datenverdacht; hilft
  das nicht -> sauber stoppen mit klarer Meldung "Demo-Server/Daten pruefen".
- Manueller Fallback bleibt: genau der dokumentierte Fall, in dem der Nutzer
  eingreift (Login/Datenbezug). Der Loop macht den Ausfall sichtbar, verschluckt
  ihn nicht.

### 5. Scope: Bau ist Folge-Vorhaben (Top-Prioritaet)
Die Karte schreibt nur den Zielgrad fest (planen, nicht bauen). Der eigentliche Bau
von run_backtest.ps1 + parse_report.py + .ini-Vorlage ist das erste und vorrangige
Folge-Vorhaben -- weil ohne die Pipeline nichts anderes praktikabel laeuft.

### Folgen / Nebel
- "Ziel-Repo-Struktur & Skill/Tool-Kuratierung" (hing an 05+08) ist jetzt scharf
  -> graduiert zu Ticket 10.
