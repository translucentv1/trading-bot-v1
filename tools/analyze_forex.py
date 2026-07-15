# Rechnet ein Mean-Reversion-Signal (rollierender Z-Score) ueber eine
# von fetch_forex.py erzeugte CSV und misst, ob es einen Edge hat -
# getrennt nach Out-of-Sample-Fenster A und B (Split-Datum). Ausgabe:
# nur ein paar Kennzahlen, die Rohkerzen bleiben in der Datei (spart
# Claude-Kontext / Token).
#
# Nur Standard-Bibliothek - kein pip install noetig.
#
# Idee des Signals (Mean Reversion):
#   rollierender Mittelwert m und Standardabw. s der letzten N Closes.
#   z = (close - m) / s.
#   z <= -schwelle -> Kurs "zu tief" -> Wette LONG (Rueckkehr nach oben)
#   z >= +schwelle -> Kurs "zu hoch" -> Wette SHORT (Rueckkehr nach unten)
#   Ergebnis = Rendite ueber die naechsten h Kerzen in Wett-Richtung.
#
# Wichtig (Ehrlichkeit): Trades werden NICHT ueberlappt (nach einem Trade
# erst wieder nach h Kerzen ein neuer). Ueberlappende Fenster wuerden die
# Signifikanz (t/z) kuenstlich aufblasen.
#
# t-Statistik (Edge-Nachweis, vgl. CLAUDE.md-Disziplin |z| > 2):
#   z_edge = Mittelwert(Rendite) / (Stdabw / sqrt(Anzahl Trades))
#   |z_edge| > 2  =>  Mittel statistisch von Null verschieden.
#
# Beispiele:
#   python tools/analyze_forex.py data/EURUSD_1day.csv
#   python tools/analyze_forex.py data/EURUSD_1day.csv --window 20 \
#       --schwelle 2.0 --horizont 5 --split 2017-01-01
#
# Optionen (mit Standardwerten):
#   --window N     Laenge des rollierenden Fensters   (20)
#   --schwelle X   Z-Score-Schwelle fuer ein Signal   (2.0)
#   --horizont H   Halte-Kerzen bis Ausstieg          (5)
#   --split DATUM  Grenze Fenster A|B (YYYY-MM-DD)     (Mitte der Daten)

import math
import statistics
import sys


def parse_args(argv):
    opts = {"window": 20, "schwelle": 2.0, "horizont": 5, "split": None}
    if not argv or argv[0].startswith("--"):
        sys.exit("Aufruf: python tools/analyze_forex.py PFAD.csv [Optionen]")
    path = argv[0]
    i = 1
    keys = {"--window": ("window", int), "--schwelle": ("schwelle", float),
            "--horizont": ("horizont", int), "--split": ("split", str)}
    while i < len(argv):
        if argv[i] in keys and i + 1 < len(argv):
            name, cast = keys[argv[i]]
            opts[name] = cast(argv[i + 1])
            i += 2
        else:
            sys.exit(f"Unbekannte oder unvollstaendige Option: {argv[i]}")
    return path, opts


def load(path):
    """Liest datetime;open;high;low;close (aufsteigend) -> Listen."""
    dates, closes = [], []
    with open(path, encoding="utf-8") as fh:
        header = fh.readline().strip().split(";")
        try:
            di, ci = header.index("datetime"), header.index("close")
        except ValueError:
            sys.exit(f"FEHLER: Header ohne datetime/close: {header}")
        for line in fh:
            parts = line.rstrip("\n").split(";")
            if len(parts) <= max(di, ci):
                continue
            try:
                closes.append(float(parts[ci]))
                dates.append(parts[di])
            except ValueError:
                continue
    if len(closes) < 50:
        sys.exit(f"FEHLER: zu wenige Zeilen ({len(closes)}) in {path}.")
    return dates, closes


def signals(dates, closes, window, schwelle, horizont):
    """Liefert Trades als (datum, richtung, rendite) - nicht ueberlappend."""
    trades = []
    next_free = 0  # Index, ab dem der naechste Trade erlaubt ist
    last = len(closes) - horizont  # letzter Einstieg mit vollem Horizont
    for t in range(window, last):
        if t < next_free:
            continue
        fenster = closes[t - window:t]
        m = statistics.fmean(fenster)
        s = statistics.pstdev(fenster)
        if s == 0:
            continue
        z = (closes[t] - m) / s
        entry, exit_ = closes[t], closes[t + horizont]
        if z <= -schwelle:            # LONG-Wette
            r = (exit_ - entry) / entry
        elif z >= schwelle:           # SHORT-Wette
            r = (entry - exit_) / entry
        else:
            continue
        richtung = "LONG" if z <= -schwelle else "SHORT"
        trades.append((dates[t], richtung, r))
        next_free = t + horizont      # keine Ueberlappung
    return trades


def kennzahlen(trades):
    """n, Trefferquote, Mittel-Rendite (bps), Stdabw, z_edge."""
    n = len(trades)
    if n < 2:
        return {"n": n, "hit": None, "mean_bps": None, "z_edge": None}
    rs = [r for _, _, r in trades]
    mean = statistics.fmean(rs)
    sd = statistics.pstdev(rs)
    hit = sum(1 for r in rs if r > 0) / n
    z_edge = mean / (sd / math.sqrt(n)) if sd > 0 else float("inf")
    return {"n": n, "hit": hit, "mean_bps": mean * 1e4, "z_edge": z_edge}


def zeile(label, k):
    if k["n"] < 2:
        return f"  {label:12s} n={k['n']:>4}  (zu wenige Trades)"
    return (f"  {label:12s} n={k['n']:>4}  Treffer={k['hit']*100:5.1f}%  "
            f"Mittel={k['mean_bps']:+7.2f} bps  z_edge={k['z_edge']:+6.2f}")


def main():
    path, o = parse_args(sys.argv[1:])
    dates, closes = load(path)
    trades = signals(dates, closes, o["window"], o["schwelle"], o["horizont"])

    split = o["split"] or dates[len(dates) // 2]
    a = [t for t in trades if t[0] < split]
    b = [t for t in trades if t[0] >= split]

    print(f"Datei:     {path}   ({len(closes)} Kerzen, "
          f"{dates[0]} .. {dates[-1]})")
    print(f"Signal:    window={o['window']}  schwelle={o['schwelle']}  "
          f"horizont={o['horizont']}  (nicht ueberlappend)")
    print(f"Split A|B: {split}")
    print(zeile("Gesamt", kennzahlen(trades)))
    print(zeile(f"A (<{split})", kennzahlen(a)))
    print(zeile(f"B (>={split})", kennzahlen(b)))
    print("Lesart: |z_edge| > 2 in BEIDEN Fenstern = robuster Kandidat; "
          "sonst wahrscheinlich Rauschen.")


if __name__ == "__main__":
    main()
