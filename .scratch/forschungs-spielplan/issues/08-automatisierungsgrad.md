# 08 -- Automatisierungsgrad des Backtest-Laufs festlegen

Type: grilling
Status: open
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
