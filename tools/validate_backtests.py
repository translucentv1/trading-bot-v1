# Validiert backtests.csv objektiv: rechnet Kennzahlen unabhaengig nach
# und meldet Abweichungen. Mit --write werden risk_realized_pct und
# z_score aus den Rohdaten (trades, win_rate, avg_win, avg_loss) neu
# berechnet und in die CSV geschrieben (2 Dezimalen).
#
# Formeln (Vereinbarung siehe CLAUDE.md / Auftrag vom 12.07.2026):
#   E  = p*W + (1-p)*L                        (Erwartung pro Trade)
#   SE = sqrt(p*(W-E)^2 + (1-p)*(L-E)^2) / sqrt(n)
#   z  = E / SE            (Trades als unabhaengig angenommen)
#   risk_realized_pct = |L| / 10000 * 100     (alle Laeufe: 10.000 EUR)
# Konsistenz-Warnungen (werden NICHT geschrieben, nur gemeldet):
#   PF_calc  = (p*W) / ((1-p)*|L|)  vs. Spalte profit_factor
#   Net_calc = E * n                vs. Spalte net_profit
import csv, math, sys

PATH = "backtests.csv"
DEPOSIT = 10000.0
WRITE = "--write" in sys.argv

def f(x):
    try: return float(x)
    except (ValueError, TypeError): return None

rows = list(csv.DictReader(open(PATH, encoding="utf-8"), delimiter=";",
                           restkey="_extra"))
warn, fixed = [], 0

# Schutz: Zeilen mit zu vielen Feldern (Semikolon im Fazit?) -> Abbruch
# VOR jedem Schreiben, damit die CSV nie halb geschrieben wird.
bad = [r["id"] for r in rows if r.get("_extra")]
if bad:
    print(f"FEHLER: zu viele Felder (Semikolon im Text?) in id {bad} - "
          "nichts geschrieben.")
    sys.exit(1)
for r in rows:
    r.pop("_extra", None)

for r in rows:
    n  = f(r["trades"]); p = f(r["win_rate_pct"])
    W  = f(r["avg_win"]); L = f(r["avg_loss"])
    if None in (n, p, W, L) or n <= 0:
        continue
    p /= 100.0
    E  = p*W + (1-p)*L
    var = p*(W-E)**2 + (1-p)*(L-E)**2
    se  = math.sqrt(var)/math.sqrt(n) if var > 0 else 0.0
    z   = E/se if se > 0 else None
    risk = abs(L)/DEPOSIT*100.0

    # Vergleich mit eingetragenen Werten
    for col, calc, tol in (("z_score", z, 0.06), ("risk_realized_pct", risk, 0.06)):
        old = f(r[col])
        if calc is None:
            continue
        if old is not None and abs(old-calc) > tol:
            warn.append(f"id {r['id']}: {col} eingetragen {old} vs berechnet {calc:.2f}")
        if WRITE:
            r[col] = f"{calc:.2f}"
            fixed += 1

    # Konsistenz-Checks (nur Warnung)
    pf = f(r["profit_factor"]); net = f(r["net_profit"])
    if pf is not None and L < 0 and p < 1:
        pf_calc = (p*W)/((1-p)*abs(L))
        if abs(pf_calc-pf) > 0.05:
            warn.append(f"id {r['id']}: PF {pf} vs aus W/L berechnet {pf_calc:.2f}")
    if net is not None:
        net_calc = E*n
        if abs(net_calc-net) > max(20.0, abs(net)*0.02):
            warn.append(f"id {r['id']}: net {net} vs E*n {net_calc:.0f}")

if warn:
    print("ABWEICHUNGEN/WARNUNGEN:")
    for w in warn: print(" -", w)
else:
    print("Keine Abweichungen gefunden.")

if WRITE:
    # erst in Temp-Datei schreiben, dann ersetzen (nie halbe CSV hinterlassen)
    import os
    tmp = PATH + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as out:
        wtr = csv.DictWriter(out, fieldnames=rows[0].keys(), delimiter=";")
        wtr.writeheader(); wtr.writerows(rows)
    os.replace(tmp, PATH)
    print(f"{fixed} Werte neu berechnet und geschrieben.")
