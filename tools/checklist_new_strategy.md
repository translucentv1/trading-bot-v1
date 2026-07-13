# Checkliste fuer neue Strategie-Ideen
> Aus AI-Studio-Review (docs/REVIEW_VERBESSERUNG.md, Anhang B, 13.07.2026).
> Bevor eine neue Idee in den Workflow geht: alle 10 Punkte muessen mit "Ja"
> beantwortet sein. Sonst: Idee verwerfen oder ueberarbeiten.

- [ ] **Hypothese in max. 3 Saetzen formuliert?**
  Wenn nicht: zurueck an Stratege. Eine unklare Hypothese produziert
  unklaren Code und unklare Ergebnisse.

- [ ] **A-priori-Parameter festgelegt (kein Optimieren)?**
  Alle Werte VOR dem Backtest schriftlich fixieren. Kein "mal schauen, was
  sich einstellt". Multiple-Hypothesis-Tests (z.B. 3 Thresholds) sind
  erlaubt, aber vorab definiert.

- [ ] **Test-Plan mit OOS-Fenster A/B + mind. 1 Zweitinstrument definiert?**
  Fenster A = 2022-2023, Fenster B = 2024-2026. Mindestens ein weiteres
  Instrument (nicht nur EURUSD).

- [ ] **Abbruch-Kriterium numerisch festgelegt?**
  Z.B. "gepoolt PF < 0,95 in einem Fenster" oder "|z| < 1,0". Ohne
  Abbruchkriterium wird an toten Pferden weitergearbeitet.

- [ ] **Erfolgskriterien numerisch festgelegt (|z| > 2, PF > 1)?**
  Ziel: gepoolt |z| > 2 UND PF > 1,0 in BEIDEN Fenstern. Das ist der
  strenge Standard des Projekts.

- [ ] **Strukturell verschieden von allen 6 verworfenen Strategie-Familien?**
  Verworfen: EMA-Kreuz, Mean-Reversion (RSI), Vol-Filter, Swing-Struktur
  (Fractals), ORB-Breakout, Pair-Trading-Default (ohne Cointegration-Check).
  Jede neue Idee muss einen anderen Mechanismus nutzen.

- [ ] **Im MT5-Tester ohne externe Daten testbar?**
  MT5 Calendar API, Tick-Volume, ATR, MQL5-eigene Berechnungen - ja.
  Externe Kalender-Feeds, Python-Skripte, Custom-Symbols - nein (oder nur
  als nachtraegliche Validierung).

- [ ] **Transaktionskosten-Modell beruecksichtigt?**
  Spread, Kommission, Swap, Slippage. Bei Pair-Trading: 2x alles.
  Kosten-Check VOR Signalgenerierung, nicht nur im Nachhinein.

- [ ] **Look-Ahead-Bias ausgeschlossen (Code-Review)?**
  Alle Datenzugriffe auf Index ab 1, nicht 0. Hedge-Ratio/Regression
  nur aus geschlossenen Kerzen. Code-Review durch Claude Free #1.

- [ ] **OnTester-Format kompatibel zu bestehendem Schema?**
  Identische Spalten wie ema_mtf_v3.mq5. Neue Spalten nur ANHAENGEN,
  nicht umbenennen. pool_backtests.py muss ohne Aenderung funktionieren.

---
_Quelle: docs/REVIEW_VERBESSERUNG.md, Anhang B, 13.07.2026_
