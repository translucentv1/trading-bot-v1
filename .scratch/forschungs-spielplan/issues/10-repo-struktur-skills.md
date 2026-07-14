# 10 -- Ziel-Repo-Struktur & Skill/Tool-Kuratierung

Type: grilling
Status: open
Blocked by: -

## Question

Wie soll das Repo strukturiert und die Werkzeuge kuratiert sein, damit der
Spielplan (Protokoll 05 + Automatisierung 08) sauber darin lebt?
- tools/-Layout: wo liegen run_backtest.ps1, parse_report.py, .ini-Vorlage,
  DSR-/Validate-Skripte, Heatmap-Auswertung? Ein Unterordner (z.B. tools/pipeline/)?
- backtests.csv-Erweiterung: neue Spalten aus 05 (`hypothese`) und ggf. WF-Zyklus,
  Fenster-ID, DSR-Wert -- welche Spalten kommen dazu, ohne den Header zu ueberladen?
- Skill/Tool-Kuratierung: welche der vorhandenen Skills bleiben fuer diese
  Forschungsarbeit relevant, welche koennen weg (Token-Hygiene, vgl. bereits
  gesenkter Bloat)?
- Ablage von WF-/Optimierungs-Reports (XML) und Heatmaps -- versioniert oder
  gitignored?
- Verhaeltnis zu KONTEXT.md/JOURNAL.md/EA_CODE.md (Synchron-Halten-Regeln bleiben).

Graduiert aus dem Nebel nach Aufloesung von 05 + 08 (Protokoll + Automatisierungs-
grad stehen, also ist die Ziel-Struktur jetzt scharf). Frontier: startklar.
