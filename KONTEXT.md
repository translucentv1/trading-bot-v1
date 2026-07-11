# KONTEXT – Handoff zwischen Claude Code und AI Studio
_Letzte Aktualisierung: 12.07.2026_

## Projekt
MQL5 Expert Advisor fuer MetaTrader 5.
Demo-Konto: Forex Hedged EUR, 1.000 EUR Startkapital, Hebel 1:30.
Repo (privat): https://github.com/translucentv1/trading-bot-v1

## Aktueller Stand
Phase 1 fertig. Warten auf ersten Backtest vom Nutzer.

## Letzte Aktion
experts/ema_9_21_crossover_long.mq5 fertiggestellt und gepusht.
EA noch nicht kompiliert – Nutzer muss F7 im MetaEditor druecken.

## Naechste Schritte
1. NUTZER: EA in MT5 kopieren (MQL5\Experts\), F7 kompilieren, Strategy Tester (EURUSD H4, 1.000 EUR, 1:30) starten
2. NUTZER: Screenshot / Ergebniszahlen aus Strategy Tester teilen
3. KI: Backtest-Ergebnis auswerten, Phase 2 planen

## Offene Entscheidungen
– keine –

## Kernregeln (Kurzfassung)
- Keine Kontodaten/Passwoerter/API-Keys in Code, Chat oder Commits
- Kompilieren + Strategy Tester: nur der Nutzer im MT5-Terminal
- Live-Trading: nur nach bestandenen Tests, nur durch den Nutzer
- Kommentare auf Deutsch, in .mq5-Dateien keine Umlaute (ae/oe/ue)

## Relevante Dateien
| Datei | Inhalt |
|---|---|
| experts/ema_9_21_crossover_long.mq5 | Der EA (EMA 9/21 Crossover, long-only) |
| CLAUDE.md | Vollstaendige Projektregeln |
| README.md | Setup-Anleitung fuer MT5 |
