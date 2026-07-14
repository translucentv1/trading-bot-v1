# -*- coding: utf-8 -*-
# Phase 5 Prototyp: markt-neutrales Cross-Sectional Momentum (Long/Short).
# Woechentliches Rebalancing, Terzile, dollar-neutral. Getrennt Fenster A/B,
# mit Kostenszenarien. Beta ~0 per Konstruktion -> Spread-Rendite = Alpha.
# Daten: tools/stock_export-Analog (univ_<SYM>.csv aus MT5, date;open;close;tickvol)
import csv, os, math, statistics as st

HERE=os.path.dirname(__file__)
UNIV=os.path.join(HERE,"phase5_univ")
A=("2022.01.01","2023.12.31"); B=("2024.01.01","2026.07.31")
LOOKBACK=126   # wird pro Konfig ueberschrieben
SKIP=5
HOLD=5
NEED_START="2021.01.01"  # muss Historie vor Fenster A haben (fuer 12M-Momentum)
NEED_END="2026.06.01"

def load(path):
    o={}; c={}; dates=[]
    with open(path, encoding="ascii", errors="ignore") as f:
        for d in csv.DictReader(f, delimiter=";"):
            try:
                dt=d["date"]; op=float(d["open"]); cl=float(d["close"])
                if cl<=0 or op<=0: continue
                o[dt]=op; c[dt]=cl; dates.append(dt)
            except: pass
    return o,c,sorted(dates)

# Universum laden + nach Datenverfuegbarkeit filtern (performance-unabhaengig)
data={}
for fn in os.listdir(UNIV):
    if not fn.startswith("univ_"): continue
    sym=fn[5:-4]
    o,c,dates=load(os.path.join(UNIV,fn))
    if len(dates)<400: continue
    if dates[0]>NEED_START or dates[-1]<NEED_END: continue
    data[sym]={"o":o,"c":c,"dates":set(dates)}
syms=sorted(data.keys())
print(f"Universum nach Filter: {len(syms)} Aktien")
print(" ", ", ".join(syms))

# Master-Handelskalender = Vereinigung aller Daten (die meisten Large-Caps handeln gleich)
alldates=set()
for s in syms: alldates|= set(data[s]["c"].keys())
cal=sorted(alldates)
idx={d:i for i,d in enumerate(cal)}

def close_on(s,dt):
    return data[s]["c"].get(dt)
def open_on(s,dt):
    return data[s]["o"].get(dt)

def in_win(dt,win): return win[0]<=dt<=win[1]

def run(cost_bps_side, LOOKBACK, SKIP, HOLD, rev=False):
    res={"A":[], "B":[]}
    bench={"A":[], "B":[]}  # gleichgewichteter Korb (Beta-Referenz)
    # Rebalance-Indizes: jede HOLD Tage, sofern genug Vor- und Nachlauf
    start_i=LOOKBACK+SKIP+1
    end_i=len(cal)-HOLD-2
    for t in range(start_i, end_i, HOLD):
        dt=cal[t]
        win = "A" if in_win(dt,A) else ("B" if in_win(dt,B) else None)
        if win is None: continue
        d_form_end=cal[t-SKIP]; d_form_beg=cal[t-SKIP-LOOKBACK]
        d_entry=cal[t+1]; d_exit=cal[t+1+HOLD]
        moms=[]
        for s in syms:
            cE=close_on(s,d_form_end); cB=close_on(s,d_form_beg)
            oEn=open_on(s,d_entry); oEx=open_on(s,d_exit)
            if None in (cE,cB,oEn,oEx) or cB<=0 or oEn<=0: continue
            mom=cE/cB-1.0
            ret=oEx/oEn-1.0
            moms.append((mom,ret))
        if len(moms)<9: continue
        moms.sort(key=lambda x:x[0])
        k=len(moms)//3
        if not rev:
            short_leg=moms[:k]; long_leg=moms[-k:]        # Momentum: long Gewinner
        else:
            short_leg=moms[-k:]; long_leg=moms[:k]        # Reversal: long Verlierer
        long_ret=sum(r for _,r in long_leg)/len(long_leg)
        short_ret=sum(r for _,r in short_leg)/len(short_leg)
        cost=2*(cost_bps_side/10000.0)   # rt long + rt short (voller Umschlag)
        spread=(long_ret-short_ret)-cost
        res[win].append(spread)
        bench[win].append(sum(r for _,r in moms)/len(moms))
    return res, bench

def stats(x):
    n=len(x)
    if n<2: return None
    m=sum(x)/n; sd=st.pstdev(x)
    se=sd/math.sqrt(n) if sd>0 else 0
    z=m/se if se>0 else float('nan')
    # annualisiert (woechentlich ~52/Jahr)
    ann_ret=m*52; ann_vol=sd*math.sqrt(52); sharpe=ann_ret/ann_vol if ann_vol>0 else float('nan')
    return dict(n=n, mean=m, z=z, ann_ret=ann_ret, sharpe=sharpe)

def beta(spread, bench):
    # Beta der L/S-Spread-Rendite gegen den gleichgew. Korb (soll ~0 sein)
    n=min(len(spread),len(bench))
    if n<3: return float('nan')
    xs=bench[:n]; ys=spread[:n]
    mx=sum(xs)/n; my=sum(ys)/n
    cov=sum((xs[i]-mx)*(ys[i]-my) for i in range(n))/n
    var=sum((x-mx)**2 for x in xs)/n
    return cov/var if var>0 else float('nan')

print("\n=== Cross-Sectional L/S (Terzile, dollar-neutral) ===")
# (label, lookback, skip, hold, reversal?)
configs=[
    ("MOMENTUM klassisch 12-1 monatlich", 252, 21, 21, False),
    ("MOMENTUM 6-1 woechentlich",         126, 5, 5, False),
    ("REVERSAL 5T woechentlich (mehr Trades)", 5, 0, 5, True),
    ("REVERSAL 3T (noch mehr Trades)",         3, 0, 3, True),
    ("REVERSAL 1T taeglich (max Trades)",      1, 0, 1, True),
]
periods_per_year={21:12, 10:26, 5:52, 3:84, 1:252}
for lbl,LB,SK,HD,rev in configs:
    print(f"\n### {lbl}  (Formation {LB}T-{SK}T, Halten {HD}T)")
    for cb,clbl in [(0,"brutto"),(10,"10 bps/Seite")]:
        res,bench=run(cb,LB,SK,HD,rev)
        ppy=periods_per_year.get(HD,52)
        for win in ("A","B"):
            x=res[win]; n=len(x)
            if n<2: print(f"    {clbl:12s} Fenster {win}: zu wenig"); continue
            m=sum(x)/n; sd=st.pstdev(x); se=sd/math.sqrt(n) if sd>0 else 0
            z=m/se if se>0 else float('nan')
            ann=m*ppy; sharpe=(m*ppy)/(sd*math.sqrt(ppy)) if sd>0 else float('nan')
            bval=beta(res[win],bench[win])
            print(f"    {clbl:12s} Fenster {win}: n={n:3d} | Periode={m*100:+.3f}% | "
                  f"ann={ann*100:+5.1f}% | Sharpe={sharpe:+.2f} | z={z:+.2f} | Beta={bval:+.2f}")
