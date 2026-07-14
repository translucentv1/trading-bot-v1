# Projektregeln – MQL5 Expert Advisor für MetaTrader 5

## Was ist das Projekt?
Ein MQL5 Expert Advisor (EA) für MetaTrader 5. Er wird im Strategy Tester
gebacktestet und danach auf einem **Demo-Konto** automatisiert
paper-getradet (Forex, Hedged, EUR, 1.000 EUR Startkapital, Hebel 1:30).
MQL5/MT5 ist der komplette Stack – kein Pine Script, kein Python (vorerst;
der frühere TradingView/Python-Stand liegt in der Git-Historie und kann
jederzeit wiederhergestellt werden). **Aktueller Projektstand** (Phase,
aktive Strategie, nächste Schritte) steht immer in `KONTEXT.md` – die
Phasenliste stand früher hier und veraltete, deshalb lebt sie jetzt nur
noch dort.

## Grundregeln
- **NIEMALS Kontodaten, Passwörter, Login-/Servernummern in Code, Commits
  oder Prompts/Chat.** Claude nimmt grundsätzlich keine Zugangsdaten
  entgegen und gibt keine ein – Anmeldung am Terminal macht der Nutzer
  immer selbst.
- **Kompilieren und Strategy-Tester-Läufe passieren beim Nutzer im
  MT5-Terminal, nicht bei Claude** – Ausnahmen nur mit ausdrücklicher
  Erlaubnis des Nutzers (diese liegt seit 12.07.2026 vor, siehe
  Backtest-Automatik). Die `.mq5`-Dateien unter `/experts` sind zum
  Kompilieren im MetaEditor gedacht; Claude schreibt den Code so einfach
  und standardnah wie möglich, damit er auf Anhieb kompiliert.
- Deutsche Kommentare, für Anfänger lesbar. In `.mq5`-Dateien ohne
  Umlaute (ae/oe/ue), damit es keine Zeichensatz-Probleme im MetaEditor
  gibt.

## Sicherheits-Reihenfolge (unumstößlich)
Backtest im Strategy Tester → automatisiertes Paper-Trading auf dem
Demo-Konto → eine Live-Schaltung kommt frühestens nach bestandenen,
dokumentierten Tests in Frage, ist allein Entscheidung und Handlung des
Nutzers, und wird von Claude weder ausgeführt noch aktiviert.

## Forschungs-Disziplin (Edge-Nachweis)
Jede neue Signal-Idee wird streng geprüft, bevor sie als Edge gilt:
Out-of-Sample-Fenster A/B + Gegentest auf einem zweiten Instrument, Ziel
|z| > 2 bei 1 % Risiko pro Trade. Kein Demo-/Live-Einsatz mit
Gewinnerwartung, solange kein instrument-übergreifend robuster Edge belegt
ist. (Chronik der geprüften/verworfenen Ideen: `KONTEXT.md` + backtests.csv.)

## Handoff-Workflow (Claude Code ↔ AI Studio)
`KONTEXT.md` im Repo-Root ist die gemeinsame Handoff-Datei.
- **Claude Code** aktualisiert sie am Ende jeder Sitzung und committet sie.
- **AI Studio**: Nutzer kopiert Inhalt von `KONTEXT.md` + relevante `.mq5`-Datei
  in AI Studio. AI Studio plant/diskutiert, implementiert aber nicht.
- **Zustaendigkeit**: Claude Code = Code schreiben, Git, Dateien.
  AI Studio = Planung, Erklaerungen, Strategie-Ideen (ohne Repo-Zugriff).
- Jede neue Claude-Code-Sitzung beginnt mit Lesen von `KONTEXT.md`.
- `EA_CODE.md` (Repo-Root) enthaelt den kompletten aktuellen EA-Code als
  Markdown-Block und wird bei JEDER Aenderung an der aktiven `.mq5` im
  selben Commit mitgepflegt (Uebergabe an AI Studio ohne separaten Upload).

### Protokoll-Pflicht (jeder Backtest zaehlt)
- **Jeder Backtest wird protokolliert** — eine Zeile pro Lauf in
  `backtests.csv`. Die Spaltenliste ist die Header-Zeile der Datei selbst;
  Formeln + unabhaengige Nachrechnung stehen in `tools/validate_backtests.py`.
  Kernlesart: `risk_realized_pct` soll ~1 % sein (sonst Sizing-Problem),
  `|z_score|` > ~2 = statistisch von Null verschieden (darunter Rauschen),
  Profitfaktor bei 0 Verlusten = "inf" (nicht 0). So werden Fehlschlaege
  nicht doppelt getestet.
- **Jede groessere Aenderung** wird in `KONTEXT.md` festgehalten
  (Aktueller Stand, Letzte Aktion, Backtest-Chronik) und committet.
- Automatik: Der EA schreibt via `OnTester()` die Kennzahlen nach
  `Common\Files\tester_result.txt`; Claude liest sie aus und traegt sie
  in `backtests.csv` ein. Details/Technik in der Claude-Memory
  (mt5-backtest-workflow).
- `AI_STUDIO_PROMPT.md` = fertiger Prompt fuer AI Studio (Rollen,
  Regeln, gelernte Lektionen, Workflow). Vor jeder AI-Studio-Sitzung
  aktuell halten.
- **`JOURNAL.md` = Tagebuch mit Tageseintraegen** (neuester oben). Jede
  Arbeitssitzung ergaenzt den Eintrag des Tages: gemacht / herausgekommen /
  entschieden / offen. Zahlen gehoeren in `backtests.csv`, Kontext in
  `KONTEXT.md` – das Journal ist die Zeitleiste.
- `tools/validate_backtests.py` prueft `backtests.csv` objektiv (rechnet
  z_score, risk_realized_pct, PF- und Netto-Konsistenz unabhaengig nach);
  mit `--write` traegt es die berechneten Werte ein. Nach jedem neuen
  Eintrag einmal laufen lassen.

_Hinweis: Ein von AI Studio generiertes React/Node-Web-Tool wurde bewusst
wieder entfernt – das Repo bleibt schlank auf MQL5/MT5 fokussiert._
