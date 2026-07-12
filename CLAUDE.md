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

### Protokoll-Pflicht (jeder Backtest zaehlt)
- **Jeder Backtest wird protokolliert** — eine Zeile pro Lauf in
  `backtests.csv` (id;datum;ea_version;zeitraum;exec_tf;bias_tf;richtung;
  strategie;net_profit;profit_factor;sharpe;dd_pct;trades;win_rate_pct;
  avg_win;avg_loss;max_loss_streak;fazit). Profitfaktor bei 0 Verlusten =
  "inf" (nicht 0). So bleiben die Daten dauerhaft nutzbar und
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

## Phasen
1. **Phase 1 (fertig):** Struktur, erster EA (EMA-9/21-Crossover, long-only,
   EURUSD H4, SL/TP in % vom Kapital) inkl. Tagesverlust-Stopp.
2. **Phase 2 (aktiv):** EA v2.0 mit Marktstruktur-SL, dynamischem TP,
   ATR-Trailing und RSI-Filter. Erster profitabler Backtest (PF 1,09).
   Jetzt: Robustheit pruefen und Parameter optimieren.
3. **Phase 3 (Idee):** EA v3.0 mit Zwei-Wege-Handel (Long & Short),
   symmetrische Struktur-Logik.

_Hinweis: Ein von AI Studio generiertes React/Node-Web-Tool wurde bewusst
wieder entfernt – das Repo bleibt schlank auf MQL5/MT5 fokussiert._
