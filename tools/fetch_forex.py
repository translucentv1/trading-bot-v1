# Holt Forex-Kurshistorie von Twelve Data (kostenloser Free-Tier:
# 800 Calls/Tag) und legt sie als CSV unter data/ ab. Zweck: Rohdaten
# fuer Out-of-Sample-Gegentests lokal vorhalten, damit sie NICHT in den
# Claude-Kontext geladen werden muessen (Token-Ersparnis).
#
# Nur Standard-Bibliothek - kein pip install noetig.
#
# API-Key: NIEMALS im Code. Er wird aus der Datei .env gelesen
# (Zeile:  TWELVE_DATA_API_KEY=dein_key  ). .env ist in .gitignore
# und wird nie committet. Key selbst holen (gratis, ohne Kreditkarte):
#   https://twelvedata.com/pricing  -> Free -> "Get API Key"
#
# Beispiele:
#   python tools/fetch_forex.py EUR/USD 1day
#   python tools/fetch_forex.py EUR/USD 1h 2000
#   python tools/fetch_forex.py GBP/USD 4h
#
# Argumente:  symbol  interval  [outputsize]
#   symbol     z.B. EUR/USD, GBP/USD  (Forex-Paar mit Schraegstrich)
#   interval   1min 5min 15min 30min 45min 1h 2h 4h 1day 1week 1month
#   outputsize Anzahl Kerzen (Standard 5000, Max im Free-Tier 5000)

import json
import os
import sys
import urllib.parse
import urllib.request

BASE = "https://api.twelvedata.com/time_series"
ENV_PATH = ".env"
ENV_KEY = "TWELVE_DATA_API_KEY"


def read_api_key():
    """Liest den Key aus .env. Beendet mit klarer Meldung, wenn er fehlt."""
    if not os.path.exists(ENV_PATH):
        sys.exit(
            f"FEHLER: {ENV_PATH} nicht gefunden. Lege sie an mit der Zeile:\n"
            f"  {ENV_KEY}=dein_key\n"
            "Key gratis (ohne Kreditkarte): https://twelvedata.com/pricing"
        )
    for line in open(ENV_PATH, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, _, value = line.partition("=")
        if name.strip() == ENV_KEY:
            key = value.strip().strip('"').strip("'")
            if key:
                return key
    sys.exit(f"FEHLER: {ENV_KEY} steht nicht (oder leer) in {ENV_PATH}.")


def fetch(symbol, interval, outputsize, api_key):
    """Ruft Twelve Data auf und gibt die geparste JSON-Antwort zurueck."""
    params = urllib.parse.urlencode({
        "symbol": symbol,
        "interval": interval,
        "outputsize": outputsize,
        "apikey": api_key,
        "format": "JSON",
        "timezone": "UTC",
    })
    url = f"{BASE}?{params}"
    with urllib.request.urlopen(url, timeout=30) as resp:
        data = json.load(resp)
    # Twelve Data meldet Fehler im Body mit status="error"
    if data.get("status") == "error":
        sys.exit(f"FEHLER von Twelve Data: {data.get('message', data)}")
    if "values" not in data:
        sys.exit(f"FEHLER: unerwartete Antwort ohne 'values': {data}")
    return data


def write_csv(symbol, interval, data):
    """Schreibt die Kerzen (aufsteigend nach Zeit) als CSV nach data/."""
    os.makedirs("data", exist_ok=True)
    safe = symbol.replace("/", "").upper()
    out_path = os.path.join("data", f"{safe}_{interval}.csv")
    # Twelve Data liefert neueste zuerst -> umdrehen auf aufsteigend
    values = list(reversed(data["values"]))
    cols = ["datetime", "open", "high", "low", "close"]
    with open(out_path, "w", encoding="utf-8", newline="") as fh:
        fh.write(";".join(cols) + "\n")
        for v in values:
            fh.write(";".join(str(v.get(c, "")) for c in cols) + "\n")
    return out_path, len(values)


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        sys.exit(
            "Aufruf: python tools/fetch_forex.py symbol interval [outputsize]\n"
            "Beispiel: python tools/fetch_forex.py EUR/USD 1day"
        )
    symbol = args[0]
    interval = args[1] if len(args) > 1 else "1day"
    outputsize = args[2] if len(args) > 2 else "5000"

    api_key = read_api_key()
    data = fetch(symbol, interval, outputsize, api_key)
    out_path, n = write_csv(symbol, interval, data)
    print(f"OK: {n} Kerzen fuer {symbol} ({interval}) -> {out_path}")


if __name__ == "__main__":
    main()
