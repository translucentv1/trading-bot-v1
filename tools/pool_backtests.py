# Poolt die Korb-Ergebnisse (sw_<sym>_<A|B>.txt) je Fenster und rechnet
# einen gepoolten z-Wert (2-Punkt-Approximation je Lauf, konsistent mit
# tools/validate_backtests.py).
import glob, os, math, re

BASE = os.path.dirname(os.path.abspath(__file__))

def parse(path):
    d = {}
    for line in open(path, encoding="utf-8", errors="ignore"):
        if "=" in line:
            k, v = line.strip().split("=", 1)
            d[k] = v
    return d

def num(d, k):
    try: return float(d.get(k, "nan"))
    except: return float("nan")

for win in ("A", "B"):
    files = sorted(glob.glob(os.path.join(BASE, f"sw_*_{win}.txt")))
    if not files:
        print(f"Fenster {win}: keine Dateien"); continue
    N = wins = losses = 0
    GP = GL = 0.0
    per = []          # (symbol, run-daten) fuer Varianz + Einzelcheck
    for f in files:
        d = parse(f)
        sym = os.path.basename(f).split("_")[1]
        n  = int(num(d, "trades"))
        w  = int(num(d, "win_trades"))
        l  = int(num(d, "loss_trades"))
        gp = num(d, "gross_profit")
        gl = num(d, "gross_loss")
        net= num(d, "net_profit")
        pf = d.get("profit_factor", "?")
        N += n; wins += w; losses += l; GP += gp; GL += gl
        per.append((sym, n, w, l, gp, gl, net, pf))

    if N == 0:
        print(f"Fenster {win}: 0 Trades"); continue
    E = (GP + GL) / N                    # GL ist negativ
    var = 0.0
    for (sym, n, w, l, gp, gl, net, pf) in per:
        aw = gp / w if w > 0 else 0.0
        al = gl / l if l > 0 else 0.0
        var += w * (aw - E)**2 + l * (al - E)**2
    var /= N
    se = math.sqrt(var) / math.sqrt(N) if var > 0 else 0.0
    z  = E / se if se > 0 else float("nan")
    pf_pool = GP / abs(GL) if GL != 0 else float("inf")

    print(f"===== Fenster {win} (gepoolt ueber {len(files)} Symbole) =====")
    print(f"  Trades N={N} | Wins {wins} ({wins/N*100:.1f}%) | Netto {GP+GL:+.0f} EUR")
    print(f"  Erwartung/Trade E={E:+.2f} | PF_pool={pf_pool:.2f} | z={z:.2f}")
    print(f"  Einzel-Symbole (Netto / PF):")
    for (sym, n, w, l, gp, gl, net, pf) in per:
        print(f"    {sym}: {net:+8.0f}  PF {pf}  ({n} Trades)")
    print()
