# Projektregeln – MQL5 Expert Advisor für MetaTrader 5

## Was ist das Projekt?
Ein MQL5 Expert Advisor (EA) für MetaTrader 5. Er wird im Strategy Tester
gebacktestet und danach auf einem **Demo-Konto** automatisiert
paper-getradet (Forex, Hedged, EUR, 1.000 EUR Startkapital, Hebel 1:30).
MQL5/MT5 ist der komplette Stack – kein Pine Script, kein Python (vorerst;
der frühere TradingView/Python-Stand liegt in der Git-Historie und kann
jederzeit wiederhergestellt werden).

## Grundregeln
- **NIEMALS Kontodaten, Passwörter, Login-/Servernummern in Code, Commits
  oder Prompts/Chat.** Claude nimmt grundsätzlich keine Zugangsdaten
  entgegen und gibt keine ein – Anmeldung am Terminal macht der Nutzer
  immer selbst.
- **Tech-Stack:** MQL5 (Expert Advisors) für MetaTrader 5. Die Dateien
  unter `/experts` sind zum Kompilieren im MetaEditor gedacht.
- **Kompilieren und Strategy-Tester-Läufe passieren beim Nutzer im
  MT5-Terminal, nicht bei Claude** – Ausnahmen nur mit ausdrücklicher
  Erlaubnis des Nutzers (diese liegt seit 12.07.2026 vor, siehe
  Backtest-Automatik). Claude schreibt den Code so einfach und
  standardnah wie möglich, damit er auf Anhieb kompiliert.
- Vor jeder größeren strukturellen Änderung: kurzer Plan im Chat, keine
  Überraschungen.
- Deutsche Kommentare, für Anfänger lesbar. In `.mq5`-Dateien ohne
  Umlaute (ae/oe/ue), damit es keine Zeichensatz-Probleme im MetaEditor
  gibt.

## Sicherheits-Reihenfolge (unumstößlich)
Backtest im Strategy Tester → automatisiertes Paper-Trading auf dem
Demo-Konto → eine Live-Schaltung kommt frühestens nach bestandenen,
dokumentierten Tests in Frage, ist allein Entscheidung und Handlung des
Nutzers, und wird von Claude weder ausgeführt noch aktiviert.

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
  `backtests.csv` (id;datum;ea_version;zeitraum;symbol;exec_tf;bias_tf;
  richtung;strategie;net_profit;profit_factor;sharpe;dd_pct;trades;
  win_rate_pct;avg_win;avg_loss;max_loss_streak;risk_realized_pct;z_score;
  fazit). Profitfaktor bei 0 Verlusten = "inf" (nicht 0).
  risk_realized_pct = |avg_loss|/Kontostand*100 (soll ~1% sein, sonst
  Sizing-Problem). z_score = Erwartung/Standardfehler (|z|>~2 = statistisch
  von Null verschieden; darunter Rauschen). So bleiben die Daten nutzbar und
  Fehlschlaege werden nicht doppelt getestet.
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

## Phasen
1. **Phase 1 (fertig):** Struktur, erster EA (EMA-9/21-Crossover, long-only,
   EURUSD H4, SL/TP in % vom Kapital) inkl. Tagesverlust-Stopp.
2. **Phase 2 (fertig):** EA v2.0 mit Marktstruktur-SL, dynamischem TP,
   ATR-Trailing und RSI-Filter. Erster profitabler Backtest (PF 1,09).
3. **Phase 3 (aktiv, Forschungsphase):** EA v3.x (Long & Short, Multi-
   Timeframe-Bias, Gewinnsicherung, Vol-Filter – alles per Toggle) als
   generisches Test-Geruest. Stand: KEINE getestete Signal-Idee hat einen
   instrument-uebergreifend robusten Edge gezeigt (siehe backtests.csv,
   z-Werte). Gesucht wird eine grundlegend neue Signal-Idee; jede neue
   Idee wird streng geprueft: Out-of-Sample-Fenster A/B + GBPUSD-Gegentest,
   Ziel |z| > 2 bei 1 % Risiko. Kein Demo-/Live-Einsatz mit
   Gewinnerwartung vorher.

_Hinweis: Ein von AI Studio generiertes React/Node-Web-Tool wurde bewusst
wieder entfernt – das Repo bleibt schlank auf MQL5/MT5 fokussiert._
