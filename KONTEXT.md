# KONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 12.07.2026_

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Konto: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
Repo (privat): https://github.com/translucentv1/trading-bot-v1

## Aktueller Stand
Phase 2 begonnen. EA v1.10 mit Trendfilter (EMA 200) bereit fuer Backtest 2.

## Letzte Aktion
AI Studio hat Trendfilter (EMA 200) zum EA hinzugefuegt.
Claude Code hat den Compile-Fehler behoben (`False` → `false`, Zeile 188)
und alle Aenderungen ins Repo uebernommen.

## Backtest-Chronik

### Backtest 1 – Ohne Trendfilter (11.07.2026)
- Symbol / Zeitrahmen: EURUSD H4
- Zeitraum: 01.01.2026 – 11.07.2026
- Einlage: 10.000 USD, Hebel 1:33
- Netto-PnL: -170,80 EUR (Endsaldo: 9.829,20 EUR)
- Profitfaktor: 0,67
- Trefferquote: 10,53 % (2 von 19 Trades gewonnen)
- Erwartetes Ergebnis: -8,99 EUR / Trade
- Sharpe-Ratio: -0,83
- Max. Verlusttrades in Folge: 11 (Durchschnitt 9)
- LR-Korrelation: -0,72 (gleichmaessig fallend – viele Fehlsignale)
- Fazit: Zu viele Fehlsignale in Seitwärts- und Abwaertsphasen.

### Backtest 2 – Mit Trendfilter EMA 200 (steht aus)
- Getestete Aenderung: Kaeufe nur wenn EMA 9 > EMA 200
- Parameter: EURUSD H4 / 01.01.2026 – 11.07.2026 / gleiche Einlage
- Ergebnisse: [ noch einzutragen ]

## Naechste Schritte
1. NUTZER: Neue .mq5-Datei aus experts/ in MQL5\Experts\ kopieren
2. NUTZER: F7 kompilieren (0 errors erwartet)
3. NUTZER: Strategy Tester starten – gleiche Parameter wie Backtest 1
   (EURUSD H4, 01.01.2026–11.07.2026, 1.000 EUR, Hebel 1:30)
4. NUTZER: Ergebnisse hier eintragen (oben in Backtest 2)
5. KI: Ergebnisse auswerten, naechsten Schritt planen

## Empfehlung fuer Backtest 2+
Zusaetzlich Testzeitraum auf 01.01.2023–12.07.2026 ausweiten (3,5 Jahre,
100+ Trades) um statistisch belastbare Ergebnisse zu bekommen.
Einmal mit InpUseTrendFilter=true und einmal mit false testen.

## Offene Entscheidungen nach Backtest 2
Falls Trendfilter hilft → naechste Option waehlen:
- ATR-basierter dynamischer Stop-Loss (ersetzt festen %-SL)
- Short-Logik aktivieren (Zwei-Wege-Handel)

## Kernregeln (Kurzfassung)
- Keine Kontodaten/Passwoerter/API-Keys in Code, Chat oder Commits
- Kompilieren + Strategy Tester: nur der Nutzer im MT5-Terminal
- Live-Trading: nur nach bestandenen Tests, nur durch den Nutzer
- Kommentare auf Deutsch, in .mq5-Dateien keine Umlaute (ae/oe/ue)

## Relevante Dateien
| Datei | Inhalt |
|---|---|
| experts/ema_9_21_crossover_long.mq5 | EA v1.10 (EMA 9/21 + Trendfilter EMA 200) |
| CLAUDE.md | Vollstaendige Projektregeln + Handoff-Workflow |
| README.md | Setup-Anleitung fuer MT5 |
