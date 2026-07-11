# Trading-Bot: TradingView-Strategien + Signal-Bot

Pine-Script-Strategien für TradingView, die dort gebacktestet und
paper-getradet werden. Langfristig soll ein Python-Bot die Strategie-Signale
automatisiert an eine Broker-API weiterleiten – **paper zuerst, live erst
nach bestandenen Tests**.

## Projektstruktur

```
strategy/   Pine-Script-v6-Strategien (zum Copy-Paste in den Pine-Editor)
bot/        Python-Bot (Phase 1: nur Risikomanagement-Logik + Tests,
            Broker-/Webhook-Anbindung folgt in Phase 2)
```

## Einrichtung (einmalig)

```powershell
cd C:\Users\phili\trading-bot
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

## Tests ausführen

```powershell
venv\Scripts\activate
python -m pytest
```

## Strategie in TradingView benutzen

1. Chart öffnen (z. B. BTCUSD, 4-Stunden-Kerzen).
2. Unten den **Pine Editor** öffnen, Inhalt einer Datei aus `strategy/`
   hineinkopieren.
3. „Zum Chart hinzufügen" klicken und im **Strategy Tester** die
   Backtest-Ergebnisse ansehen.

## Phasen

| Phase | Inhalt | Status |
|---|---|---|
| 1 | Struktur, erste Pine-Strategie (EMA 9/21), Risiko-Modul + Tests | ✅ fertig |
| 2 | Broker-/Asset-Entscheidung, Webhook, Paper-Trading-Anbindung | offen |
| 3+ | Live erst nach bestandenen Paper-Tests und ausdrücklicher Freigabe | offen |
