# Holt Kurshistorie von Yahoo Finance (gratis, KEIN API-Key) und legt sie
# als CSV unter data/ ab. Liefert tiefe Historie (Aktien teils ab 1980) -
# deutlich mehr als der Twelve-Data-Free-Tier. Zweck: belastbare
# Out-of-Sample-Fenster A/B fuer den Aktien-Korb.
#
# Nur Standard-Bibliothek - kein pip install, kein Key.
#
# Split-/Dividenden-Anpassung: Die Spalte close ist Yahoos adjClose; open/
# high/low werden mit demselben Faktor zurueckgerechnet. So erzeugen Splits
# (z. B. AAPL 4:1) keine kuenstlichen Kursspruenge -> keine Scheinsignale.
#
# Ausgabeformat identisch zu fetch_forex.py (datetime;open;high;low;close,
# aufsteigend), damit tools/analyze_forex.py direkt darueber laufen kann.
#
# Hinweis: Der v8-Chart-Endpoint ist inoffiziell und kann zeitweise
# ratelimiten (dann HTTP 429) - einfach spaeter erneut versuchen.
#
# Symbol-Schreibweise (Yahoo-Ticker, keine Suffixe fuer US-Werte):
#   US-Aktien:  AAPL  AMD  AMZN  AVGO      Indizes: ^GSPC (S&P500) ^NDX (Nasdaq100)
#   Forex:      EURUSD=X  GBPUSD=X          Krypto:  BTC-USD
#
# Beispiele:
#   python tools/fetch_yahoo.py AAPL
#   python tools/fetch_yahoo.py AAPL d 2010-01-01 2024-12-31
#   python tools/fetch_yahoo.py ^NDX w
#
# Argumente:  symbol  [interval]  [von]  [bis]
#   interval  d (taeglich, Standard) | w (woechentlich) | m (monatlich)
#   von/bis   optionaler Zeitraum als YYYY-MM-DD (Standard: gesamte Historie)

import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
INTERVALS = {"d": "1d", "w": "1wk", "m": "1mo"}


def parse_args(argv):
    if not argv or argv[0] in ("-h", "--help"):
        sys.exit("Aufruf: python tools/fetch_yahoo.py symbol [d|w|m] [von] [bis]\n"
                 "Beispiel: python tools/fetch_yahoo.py AAPL d 2010-01-01 2024-12-31")
    symbol = argv[0]
    key = argv[1] if len(argv) > 1 else "d"
    if key not in INTERVALS:
        sys.exit(f"FEHLER: interval muss d, w oder m sein (war: {key}).")
    von = to_unix(argv[2]) if len(argv) > 2 else 0
    bis = to_unix(argv[3]) if len(argv) > 3 else int(dt.datetime.now().timestamp())
    return symbol, key, INTERVALS[key], von, bis


def to_unix(datum):
    try:
        return int(dt.datetime.strptime(datum, "%Y-%m-%d").timestamp())
    except ValueError:
        sys.exit(f"FEHLER: Datum muss YYYY-MM-DD sein (war: {datum}).")


def fetch(symbol, interval, von, bis):
    url = (BASE.format(symbol=urllib.parse.quote(symbol))
           + f"?period1={von}&period2={bis}&interval={interval}")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        hint = " (ratelimit - spaeter erneut versuchen)" if e.code == 429 else ""
        sys.exit(f"FEHLER {e.code} von Yahoo{hint}.")
    chart = data.get("chart", {})
    if chart.get("error"):
        sys.exit(f"FEHLER von Yahoo: {chart['error']}")
    res = chart.get("result")
    if not res or not res[0].get("timestamp"):
        sys.exit(f"FEHLER: keine Daten fuer '{symbol}'. Ticker korrekt? "
                 "(US-Aktien ohne Suffix, Forex z. B. EURUSD=X)")
    return res[0]


def to_rows(result):
    """Baut split-/dividenden-angepasste OHLC-Zeilen (aufsteigend)."""
    ts = result["timestamp"]
    q = result["indicators"]["quote"][0]
    adj = result["indicators"].get("adjclose", [{}])[0].get("adjclose")
    o, h, l, c = q["open"], q["high"], q["low"], q["close"]
    rows = []
    for i, t in enumerate(ts):
        close = c[i]
        if close is None or o[i] is None:
            continue  # Yahoo setzt bei Luecken None
        ac = adj[i] if adj and adj[i] is not None else close
        f = ac / close if close else 1.0  # Anpassungsfaktor
        datum = dt.datetime.fromtimestamp(t, dt.UTC).date().isoformat()
        rows.append([datum, o[i] * f, h[i] * f, l[i] * f, ac])
    if len(rows) < 2:
        sys.exit("FEHLER: zu wenige gueltige Datenzeilen.")
    return rows


def fmt(x):
    return f"{x:.4f}".rstrip("0").rstrip(".")


def write_csv(symbol, key, rows):
    os.makedirs("data", exist_ok=True)
    safe = (symbol.replace("^", "idx_").replace("=X", "").replace("-", "_")
            .upper())
    out_path = os.path.join("data", f"{safe}_{key}.csv")
    with open(out_path, "w", encoding="utf-8", newline="") as fh:
        fh.write("datetime;open;high;low;close\n")
        for r in rows:
            fh.write(f"{r[0]};{fmt(r[1])};{fmt(r[2])};{fmt(r[3])};{fmt(r[4])}\n")
    return out_path


def main():
    symbol, key, interval, von, bis = parse_args(sys.argv[1:])
    result = fetch(symbol, interval, von, bis)
    rows = to_rows(result)
    out_path = write_csv(symbol, key, rows)
    print(f"OK: {len(rows)} Kerzen fuer {symbol} ({key}), "
          f"{rows[0][0]} .. {rows[-1][0]} -> {out_path}")


if __name__ == "__main__":
    main()
