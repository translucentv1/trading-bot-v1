# Poolt Korb-Backtest-Ergebnisdateien je Fenster (A/B) und rechnet einen
# gepoolten z-Wert (2-Punkt-Approximation je Lauf, konsistent mit
# tools/validate_backtests.py). Fuer die Pooling-Methodik (Backtest 12+).
#
# Aufruf:  python pool_backtests.py <prefix> <verzeichnis>
#   prefix      = Datei-Praefix, z.B. "sw" oder "orb"
#   verzeichnis = Ordner mit <prefix>_<Symbol>_<A|B>.txt (Default: .)
# Jede Ergebnisdatei ist key=value (aus OnTester): trades, win_trades,
# loss_trades, gross_profit, gross_loss, net_profit, profit_factor.
import glob, os, math, sys

prefix = sys.argv[1] if len(sys.argv) > 1 else "sw"
resdir = sys.argv[2] if len(sys.argv) > 2 else "."

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
    files = sorted(glob.glob(os.path.join(resdir, f"{prefix}_*_{win}.txt")))
    if not files:
        print(f"Fenster {win}: keine Dateien ({prefix}_*_{win}.txt)"); continue
    N = wins = losses = 0
    GP = GL = 0.0
    per = []
    for f in files:
        d = parse(f)
        sym = os.path.basename(f).split("_")[1]
        n  = int(num(d, "trades"))
        # Einheitlich aus Trefferquote/Ø ableiten (beide EA-OnTester-Formate);
        # direkte Felder nur als Fallback, falls vorhanden.
        wr = num(d, "win_rate_pct")
        aw = num(d, "avg_win")
        al = num(d, "avg_loss")
        w  = int(round(wr/100.0*n)) if wr == wr else int(num(d, "win_trades"))
        l  = n - w
        gp = w*aw if aw == aw else num(d, "gross_profit")
        gl = l*al if al == al else num(d, "gross_loss")
        net= num(d, "net_profit")
        pf = d.get("profit_factor", "?")
        N += n; wins += w; losses += l; GP += gp; GL += gl
        per.append((sym, n, w, l, gp, gl, net, pf))
    if N == 0:
        print(f"Fenster {win}: 0 Trades"); continue
    E = (GP + GL) / N
    var = 0.0
    for (sym, n, w, l, gp, gl, net, pf) in per:
        aw = gp / w if w > 0 else 0.0
        al = gl / l if l > 0 else 0.0
        var += w * (aw - E)**2 + l * (al - E)**2
    var /= N
    se = math.sqrt(var) / math.sqrt(N) if var > 0 else 0.0
    z  = E / se if se > 0 else float("nan")
    pf_pool = GP / abs(GL) if GL != 0 else float("inf")
    print(f"===== Fenster {win} (gepoolt, {len(files)} Symbole) =====")
    print(f"  Trades N={N} | Wins {wins} ({wins/N*100:.1f}%) | Netto {GP+GL:+.0f} EUR")
    print(f"  E/Trade={E:+.2f} | PF_pool={pf_pool:.2f} | z={z:.2f}")
    for (sym, n, w, l, gp, gl, net, pf) in per:
        print(f"    {sym}: {net:+8.0f}  PF {pf}  ({n} Trades)")
    print()
