# 10 -- Ziel-Repo-Struktur & Skill/Tool-Kuratierung

Type: grilling
Status: resolved
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

## Answer

Ziel-Struktur: eine Ebene Ordnung, nicht mehr. Pipeline gebuendelt, Alt-Helfer flach,
CSV knapp + Prosa ausgelagert, Rohartefakte gitignored/Belege versioniert, Skills auf
den Spielplan kuratiert. Scope-Regel: das ist die Struktur-*Entscheidung*, die
Ausfuehrung (Loeschen/Verschieben) laeuft im Folge-Vorhaben.

### 1. tools/-Layout: Unterordner tools/pipeline/, Rest flach
- tools/pipeline/ = der End-to-End-Loop (08): run_backtest.ps1, parse_report.py,
  backtest.ini.template, DSR-/WF-Auswerteskript. Ein Ort, eine Verantwortung.
- tools/ flach = eigenstaendige Alt-Helfer: validate_backtests.py, pool_backtests.py,
  run_cointegration.sh, checklist_new_strategy.md.
- Nicht ueber-strukturieren (Solo-Repo): eine Ebene Trennung Pipeline vs. Einzelhelfer.

### 2. backtests.csv: nur 4 neue Spalten, Prosa nach hypothesen.md
Ans Header-Ende (aktuell 21 Spalten):
1. `hypothese` -- kurzer Key (z.B. H-2026-07-US100-ovngap) -> zeigt auf hypothesen.md.
2. `phase` -- Lauf-Rolle: sieben / wf-is / wf-oos / lockbox / stress (trennt, was ins
   Erfolgs-Tor zaehlt; 07: Vorab-Sieb-Laeufe nie werten).
3. `wf_zyklus` -- Walk-Forward-Zyklus-Nr. (leer bei Einzellauf), fuer >=5-Zyklen (05).
4. `dsr` -- Deflated-Sharpe-Wert.
NICHT als Spalten: Kommission/Slippage/Spread (stehen pro Instrument in der .ini,
nicht pro Zeile), Fenster-Datumsbereiche (schon in `zeitraum`).
hypothesen.md liegt im Root neben backtests.csv/JOURNAL.md (Forschungs-Register, kein
Werkzeug); Format = die 4 Felder aus Ticket 09.

### 3. Report-/Heatmap-Ablage: Roh gitignored, Belege versioniert
- Gitignored (Maschinen-Output, reproduzierbar, voluminoes): XML-Roh-Reports +
  generierte .ini-Laeufe -> Ordner reports/ in .gitignore (passt zu bestehendem
  *.ex5/*.log-Ignore).
- Versioniert (Entscheidungs-Beleg): backtests.csv-Zeile, hypothesen.md-Eintrag, und
  die Heatmap eines Schluessellaufs als kompaktes PNG -> reports/heatmaps/ NICHT
  ignoriert (.gitignore: reports/ ignorieren, !reports/heatmaps/ wieder rein).
- Prinzip: Git haelt, was eine Entscheidung belegt und nicht trivial reproduzierbar
  ist. Rohes XML ist beides nicht; die Plateau-Heatmap (05) ist der visuelle Beleg.

### 4. Skill-/Tool-Kuratierung + Altlast
- Kern behalten: wayfinder, grilling, domain-modeling (KONTEXT-Glossar), research,
  handoff.
- Engineering-Hygiene behalten (fuers Pipeline-Bau-Folgevorhaben): diagnosing-bugs,
  git-guardrails-claude-code, setup-pre-commit.
- Entfernen-Kandidaten: setup-matt-pocock-skills (Einmal-Installer, Zweck erfuellt);
  grill-me / grill-with-docs (Varianten von grilling -- redundant, wenn grilling reicht).
- Altlast raus: AI_STUDIO_PROMPT.md (ausgeschlossener GLM/AI-Studio-Pfad; aktiver Weg
  ist HANDOFF.md + handoff-Skill).
- Ausfuehrung = Folge-Vorhaben / separates Okay, nicht jetzt (planen, nicht bauen).

### Verhaeltnis zu KONTEXT.md / JOURNAL.md / EA_CODE.md
Synchron-Halten-Regeln bleiben unveraendert (CLAUDE.md): EA_CODE.md spiegelt die
aktive .mq5; nach jedem Backtest backtests.csv + validate; jede Session KONTEXT.md +
JOURNAL.md. Neu einzupflegen (Folge-Vorhaben): KONTEXT.md-Glossar um Walk-Forward,
WFE, Lockbox, Deflated Sharpe, HARKing-Budget erweitern; hypothesen.md als zusaetzliche
Chronik-Datei in denselben Synchron-Rhythmus aufnehmen.

### Damit ist die Karte komplett (10/10)
Alle grundsaetzlichen Entscheidungen stehen. Naechster Schritt ist kein Ticket mehr,
sondern das Folge-Vorhaben: den Spielplan als spec.md verdichten und die Pipeline
bauen.
