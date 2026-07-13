# Poolt aus backtests.csv (2-Punkt-Approximation, identisch zu tools/pool_backtests.py)
# ueber beliebige Symbol-Teilmengen, getrennt nach Fenster. Kein neuer Tester-Lauf -
# nur Neu-Poolen bereits erhobener Daten, um das Data-Snooping der Pool-Reduktion zu pruefen.
import csv, math, sys

PATH = sys.argv[1] if len(sys.argv) > 1 else "backtests.csv"
A = "2022-01_2023-12"
B = "2024-01_2026-07"

rows = list(csv.DictReader(open(PATH, encoding="utf-8"), delimiter=";"))

def fnum(x):
    try: return float(x)
    except: return float("nan")

def pool(strategie, zeitraum, symbols=None):
    N = wins = 0
    GP = GL = 0.0
    per = []
    for r in rows:
        if r["strategie"] != strategie: continue
        if r["zeitraum"] != zeitraum: continue
        sym = r["symbol"]
        if symbols is not None and sym not in symbols: continue
        n  = int(fnum(r["trades"]))
        wr = fnum(r["win_rate_pct"])
        aw = fnum(r["avg_win"])
        al = fnum(r["avg_loss"])
        w  = int(round(wr/100.0*n))
        l  = n - w
        gp = w*aw
        gl = l*al
        N += n; wins += w; GP += gp; GL += gl
        per.append((sym, n, w, l, gp, gl, aw, al, fnum(r["net_profit"]), r["profit_factor"]))
    if N == 0:
        return None
    E = (GP + GL) / N
    var = 0.0
    for (sym, n, w, l, gp, gl, aw, al, net, pf) in per:
        var += w*(aw - E)**2 + l*(al - E)**2
    var /= N
    se = math.sqrt(var)/math.sqrt(N) if var > 0 else 0.0
    z  = E/se if se > 0 else float("nan")
    pf_pool = GP/abs(GL) if GL != 0 else float("inf")
    return dict(N=N, wins=wins, net=GP+GL, E=E, pf=pf_pool, z=z, per=per, nsym=len(per))

def show(title, strategie, symbols=None):
    print("="*70)
    print(title)
    for win, zr in (("A 2022-2023", A), ("B 2024-2026", B)):
        res = pool(strategie, zr, symbols)
        if not res:
            print(f"  Fenster {win}: keine Daten"); continue
        print(f"  Fenster {win}: {res['nsym']} Sym | N={res['N']:4d} | "
              f"Wins {res['wins']/res['N']*100:4.1f}% | Netto {res['net']:+8.0f} | "
              f"E={res['E']:+6.2f} | PF={res['pf']:.2f} | z={res['z']:+.2f}")
    # Gesamt (beide Fenster gepoolt) - NICHT unabhaengig, nur zur Einordnung
    NA = pool(strategie, A, symbols); NB = pool(strategie, B, symbols)
    if NA and NB:
        N = NA['N']+NB['N']; wins = NA['wins']+NB['wins']
        GP = sum(p[4] for p in NA['per']+NB['per'])
        GL = sum(p[5] for p in NA['per']+NB['per'])
        E = (GP+GL)/N
        var = 0.0
        for (sym,n,w,l,gp,gl,aw,al,net,pf) in NA['per']+NB['per']:
            var += w*(aw-E)**2 + l*(al-E)**2
        var /= N
        se = math.sqrt(var)/math.sqrt(N) if var>0 else 0.0
        z = E/se if se>0 else float("nan")
        pf = GP/abs(GL) if GL!=0 else float("inf")
        print(f"  GESAMT A+B : {N} Trades | Netto {GP+GL:+.0f} | E={E:+.2f} | PF={pf:.2f} | z={z:+.2f}  (nicht unabhaengig)")
    print()

ALL10 = {"AAPL","AMD","AMZN","AVGO","ADBE","ABNB","AXP","ABT","AIG","AEP"}
POOL8  = ALL10 - {"AMZN","AIG"}                      # nachtraeglich reduziert (Snooping)
POOL4  = {"AMD","AVGO","AXP","ABNB"}                 # Top-4 laut KONTEXT (grob)

show("RSI<5 (Backtest 18) - VOLLER 10er-Pool (keine Reduktion)", "stock-mr-rsi5", ALL10)
show("RSI<5 (Backtest 18) - 8er-Pool ohne AMZN+AIG (Snooping-Reproduktion)", "stock-mr-rsi5", POOL8)
show("RSI<10 (Backtest 17) - VOLLER 10er-Pool", "stock-mr-rsi2", ALL10)

# Per-Symbol Netto beide Fenster fuer Transparenz (RSI<5)
print("="*70)
print("Per-Symbol Netto RSI<5 (A | B):")
for s in sorted(ALL10):
    ra = pool("stock-mr-rsi5", A, {s}); rb = pool("stock-mr-rsi5", B, {s})
    na = ra['net'] if ra else float('nan'); nb = rb['net'] if rb else float('nan')
    print(f"  {s:5s}: A {na:+8.0f}  |  B {nb:+8.0f}")
