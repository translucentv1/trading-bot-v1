# Projektregeln – TradingView-Strategien + Signal-Bot

## Was ist das Projekt?
Pine-Script-Strategien für TradingView (Backtest + Paper-Trading), plus ein
Python-Bot, der langfristig Strategie-Signale automatisiert an eine
Broker-API weiterleiten soll – **paper zuerst, live erst nach bestandenen,
dokumentierten Tests und ausdrücklicher Freigabe des Nutzers**.

## Arbeitsweise
- Vor jeder größeren strukturellen Änderung: kurzer Plan im Chat, keine
  Überraschungen.
- Deutsche Kommentare, für Anfänger lesbar. Berichte in einfacher Sprache
  ohne Fachjargon.
- Jede Phase wird getestet, bevor die nächste beginnt.

## Tech-Stack
- **Pine Script v6** (TradingView) für Strategien unter `/strategy`.
  Wichtig: `.pine`-Dateien können nicht automatisiert hochgeladen werden –
  sie sind zum manuellen Copy-Paste in den Pine-Editor gedacht. TradingView
  führt selbst keine automatischen Live-Trades aus; Pine-Strategien dienen
  Backtests und Signalen.
- **Python 3.x** für den Bot unter `/bot` (Broker und Asset-Klasse werden
  erst in Phase 2 entschieden). Tests mit **pytest**.
- Virtuelle Umgebung im Unterordner `venv` (aktivieren mit
  `venv\Scripts\activate`).

## Sicherheit / Grenzen
- Phase 1: kein Broker-Zugriff, keine API-Keys, keine echten Zugangsdaten.
- Niemals echte Zugangsdaten ins Repo: `.env` steht in `.gitignore`, nur
  `.env.example` mit Platzhaltern wird committet.
- Claude gibt grundsätzlich keine API-Keys/Passwörter ein und nimmt keine
  entgegen – Zugangsdaten trägt der Nutzer immer selbst ein.
- Unumstößliche Reihenfolge: Backtest → Paper-Trading → erst nach
  bestandenen Tests und ausdrücklicher Freigabe des Nutzers eine
  Live-Schaltung. Live-Trades werden niemals von Claude ausgeführt oder
  freigeschaltet.

## Phasen
1. **Phase 1 (heute):** Projektstruktur, erste Pine-Strategie
   (EMA-9/21-Crossover), Bot-Grundgerüst mit Risikomanagement + Tests.
2. **Phase 2:** Broker-/Asset-Entscheidung, Webhook-Empfang,
   Paper-Trading-Anbindung.
3. **Phase 3+:** Erst nach dokumentiert bestandenen Paper-Tests:
   Live-Überlegungen (Entscheidung und Umsetzung liegt beim Nutzer).
