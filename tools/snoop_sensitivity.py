# Zeigt, wie stark der gepoolte z-Wert davon abhaengt, WELCHE 2 von 10 Symbolen
# man streicht. Wenn 8er-Ergebnis (z=2.46) am oberen Rand der Verteilung liegt,
# ist es ein Selektions-Artefakt, kein Signal.
import csv, math, itertools

PATH = "backtests.csv"
A = "2022-01_2023-12"; B = "2024-01_2026-07"
rows = list(csv.DictReader(open(PATH, encoding="utf-8"), delimiter=";"))
def fnum(x):
    try: return float(x)
    except: return float("nan")

def cells(strategie, zeitraum, symbols):
    out=[]
    for r in rows:
        if r["strategie"]!=strategie or r["zeitraum"]!=zeitraum: continue
        if r["symbol"] not in symbols: continue
        n=int(fnum(r["trades"])); wr=fnum(r["win_rate_pct"])
        aw=fnum(r["avg_win"]); al=fnum(r["avg_loss"])
        w=int(round(wr/100*n)); l=n-w
        out.append((n,w,l,w*aw,l*al,aw,al))
    return out

def zval(cells_list):
    N=sum(c[0] for c in cells_list); GP=sum(c[3] for c in cells_list); GL=sum(c[4] for c in cells_list)
    if N==0: return float("nan"), float("nan")
    E=(GP+GL)/N
    var=sum(c[1]*(c[5]-E)**2 + c[2]*(c[6]-E)**2 for c in cells_list)/N
    se=math.sqrt(var)/math.sqrt(N) if var>0 else 0.0
    z=E/se if se>0 else float("nan")
    pf=GP/abs(GL) if GL!=0 else float("inf")
    return z, pf

ALL10=["AAPL","AMD","AMZN","AVGO","ADBE","ABNB","AXP","ABT","AIG","AEP"]

for strat,label in (("stock-mr-rsi5","RSI<5"),("stock-mr-rsi2","RSI<10")):
    print("="*66)
    print(f"{label}: Verteilung des gepoolten z ueber ALLE C(10,8)=45 Streich-Paare")
    for zr,wl in ((B,"B 2024-2026"),(A,"A 2022-2023")):
        zs=[]
        for drop in itertools.combinations(ALL10,2):
            keep=[s for s in ALL10 if s not in drop]
            z,pf=zval(cells(strat,zr,keep))
            zs.append((z,drop))
        zs_sorted=sorted(zs,reverse=True)
        zfull,_=zval(cells(strat,zr,ALL10))
        zvals=[z for z,_ in zs]
        print(f"  Fenster {wl}: voller 10er z={zfull:+.2f} | "
              f"8er min={min(zvals):+.2f} median={sorted(zvals)[len(zvals)//2]:+.2f} max={max(zvals):+.2f}")
        # wie oft ueberschreitet ein 8er-Pool |z|=2 rein durch Streichen?
        over2=sum(1 for z in zvals if z>2)
        print(f"      -> {over2}/45 der 8er-Pools erreichen z>2 allein durch Weglassen 2er Symbole")
        best=zs_sorted[0]
        print(f"      -> bester 8er: streiche {best[1]} -> z={best[0]:+.2f}")
    print()
