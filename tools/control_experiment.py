# -*- coding: utf-8 -*-
# Kontroll-Experiment (Weg A): Traegt das RSI(2)-Timing ueberhaupt etwas bei,
# oder ist der Bull-Fenster-Gewinn nur Long-Beta?
#
# Drei Arme, IDENTISCHE Exit-Logik und Kosten, nur die EINSTIEGSregel variiert:
#   SIGNAL : flat & close>SMA200 & RSI(2)<Schwelle  (Ist-Strategie)
#   BETA   : flat & close>SMA200                     (immer long im Aufwaertstrend)
#   RANDOM : flat & close>SMA200 & Zufall(p)         (Timing ohne Information)
# Exit (alle): RSI(2)>80 ODER maxhold Bars ODER Stop 3xATR (intraday).
# Daten: aus MT5 exportierte D1-Serie inkl. MT5-eigener RSI/SMA/ATR (look-ahead-frei:
# Signal aus Bar i -> Ausfuehrung Open i+1).
import csv, math, random, os, json

DATA = os.path.join(os.path.dirname(__file__), "stock_export")
SYMBOLS = ["AAPL","AMD","AMZN","AVGO","ADBE","ABNB","AXP","ABT","AIG","AEP"]
WINDOWS = {"A": ("2022.01.01","2023.12.31"), "B": ("2024.01.01","2026.07.31")}
INVALID = 1e300  # DBL_MAX-Platzhalter aus MT5, wenn Indikator noch nicht bereit

def load(sym):
    rows=[]
    with open(os.path.join(DATA,f"export_{sym}.csv"), encoding="ascii", errors="ignore") as f:
        r=csv.DictReader(f, delimiter=";")
        for d in r:
            try:
                rows.append(dict(
                    date=d["date"],
                    o=float(d["open"]), h=float(d["high"]),
                    l=float(d["low"]), c=float(d["close"]),
                    rsi=float(d["rsi"]), sma=float(d["sma"]), atr=float(d["atr"])))
            except: pass
    return rows

DATacache={s:load(s) for s in SYMBOLS}

def simulate(sym, win, entry_mode, entry_thr=10.0, exit_thr=80.0, maxhold=5,
             stop_mult=3.0, risk=100.0, rng=None, rand_p=0.0, cost_mode="none"):
    """Gibt Liste der Trade-PnL (in Konto-Einheiten) zurueck. entry_mode:
       'signal' | 'beta' | 'random'. Kosten: 'none'|'real'|'pess'."""
    data=DATacache[sym]
    d0,d1=WINDOWS[win]
    N=len(data)
    trades=[]
    in_pos=False; entry_px=0.0; stop_px=0.0; ent_i=0; shares=0.0
    for i in range(N-1):
        b=data[i]
        # nur gueltige Indikatoren
        valid = (b["sma"]<INVALID and b["atr"]<INVALID and b["rsi"]<INVALID and b["atr"]>0)
        if in_pos:
            # Tag i ist ein Halte-Tag; pruefe Stop intraday, dann Exit-Signal am Close
            # Stop: hat der heutige Low den Stop gerissen?
            if b["l"] <= stop_px:
                exit_px=stop_px
                trades.append(pnl(entry_px,exit_px,shares,cost_mode))
                in_pos=False
                continue
            bars_held = i - ent_i
            exit_sig = (b["rsi"]>exit_thr) or (bars_held>=maxhold)
            if exit_sig:
                exit_px=data[i+1]["o"]   # Ausfuehrung naechster Open
                trades.append(pnl(entry_px,exit_px,shares,cost_mode))
                in_pos=False
            continue
        # flat -> Einstiegspruefung (nur im Fenster und bei gueltigen Werten)
        if not valid: continue
        if not (d0 <= b["date"] <= d1): continue
        if b["c"] <= b["sma"]: continue   # Trend-Filter (alle Arme)
        fire=False
        if entry_mode=="signal":
            fire = b["rsi"] < entry_thr
        elif entry_mode=="beta":
            fire = True
        elif entry_mode=="random":
            fire = (rng.random() < rand_p)
        if fire:
            entry_px=data[i+1]["o"]
            stopdist=stop_mult*b["atr"]
            stop_px=entry_px-stopdist
            shares=risk/stopdist
            ent_i=i+1
            in_pos=True
    return trades

def pnl(entry_px, exit_px, shares, cost_mode):
    gross=shares*(exit_px-entry_px)
    if cost_mode=="none":
        cost=0.0
    elif cost_mode=="real":
        # realistisch retail US-Aktien: Kommission max(0.005/Aktie,1$) je Seite + ~2bp Spread/Slippage je Seite
        comm=2*max(0.005*shares,1.0)
        slip=2*0.0002*shares*entry_px
        cost=comm+slip
    elif cost_mode=="pess":
        comm=2*max(0.01*shares,1.0)
        slip=2*0.0005*shares*entry_px
        cost=comm+slip
    return gross-cost

def pool_stats(all_trades):
    """all_trades: Liste von PnL. Rueckgabe E, z, PF, N, netto, winrate."""
    N=len(all_trades)
    if N==0: return dict(N=0,E=0,z=float('nan'),pf=float('nan'),net=0,wr=0)
    net=sum(all_trades); E=net/N
    mean=E
    var=sum((x-mean)**2 for x in all_trades)/N
    se=math.sqrt(var)/math.sqrt(N) if var>0 else 0.0
    z=E/se if se>0 else float('nan')
    gp=sum(x for x in all_trades if x>0); gl=sum(x for x in all_trades if x<0)
    pf=gp/abs(gl) if gl!=0 else float('inf')
    wr=sum(1 for x in all_trades if x>0)/N*100
    return dict(N=N,E=E,z=z,pf=pf,net=net,wr=wr,se=se)

def pooled(entry_mode, win, entry_thr, cost_mode, rng=None, rand_p=0.0):
    allt=[]
    per={}
    for s in SYMBOLS:
        t=simulate(s,win,entry_mode,entry_thr=entry_thr,cost_mode=cost_mode,rng=rng,rand_p=rand_p)
        per[s]=sum(t)
        allt+=t
    st=pool_stats(allt); st["per"]=per; st["trades"]=allt
    return st

def run_all(entry_thr, cost_mode):
    print("="*74)
    print(f"### RSI(2)-Entry<{entry_thr:g}  |  Kosten={cost_mode}")
    out={}
    for win in ("A","B"):
        sig=pooled("signal",win,entry_thr,cost_mode)
        beta=pooled("beta",win,entry_thr,cost_mode)
        # Random-Null: kalibriere p so, dass ~gleich viele Trades wie Signal
        # (grobe Kalibrierung ueber beta-Trade-Zahl)
        base=pooled("beta",win,entry_thr,"none")
        target=sig["N"]
        p= min(1.0, target/max(base["N"],1))
        rng=random.Random(42)
        randE=[]; randNet=[]
        for seed in range(500):
            rng.seed(1000+seed)
            r=pooled("random",win,entry_thr,cost_mode,rng=rng,rand_p=p)
            if r["N"]>0:
                randE.append(r["E"]); randNet.append(r["net"])
        randE.sort()
        def pct(v,arr):
            k=sum(1 for a in arr if a< v); return k/len(arr)*100
        sig_pctile=pct(sig["E"],randE)
        # z auf Differenz Signal - Beta (unabh. approx)
        zdiff=(sig["E"]-beta["E"])/math.sqrt(sig["se"]**2+beta["se"]**2) if (sig["se"]>0 and beta["se"]>0) else float('nan')
        rmean=sum(randE)/len(randE); rlo=randE[int(0.025*len(randE))]; rhi=randE[int(0.975*len(randE))]
        print(f"\n Fenster {win}:")
        print(f"   SIGNAL : N={sig['N']:3d}  E={sig['E']:+6.2f}  PF={sig['pf']:.2f}  z={sig['z']:+.2f}  net={sig['net']:+.0f}")
        print(f"   BETA   : N={beta['N']:3d}  E={beta['E']:+6.2f}  PF={beta['pf']:.2f}  z={beta['z']:+.2f}  net={beta['net']:+.0f}")
        print(f"   RANDOM : E-Mittel={rmean:+6.2f}  95%-Band=[{rlo:+.2f},{rhi:+.2f}]  (p~{p:.2f}, 500 Seeds)")
        print(f"   -> Signal-E Perzentil in Random-Null: {sig_pctile:.1f}%  (>97.5% = schlaegt Zufall)")
        print(f"   -> z(Signal-Beta) = {zdiff:+.2f}   (>2 = Timing schlaegt Beta signifikant)")
        out[win]=dict(signal=strip(sig),beta=strip(beta),
                      rand_mean=rmean,rand_lo=rlo,rand_hi=rhi,
                      sig_pctile=sig_pctile,zdiff=zdiff,rand_p=p)
    return out

def strip(st):
    return {k:st[k] for k in ("N","E","z","pf","net","wr")} | {"per":st["per"]}

if __name__=="__main__":
    results={}
    for thr in (10.0,5.0):
        for cm in ("none","real","pess"):
            key=f"rsi{int(thr)}_{cm}"
            results[key]=run_all(thr,cm)
    # fuer Charts speichern
    with open(os.path.join(os.path.dirname(__file__),"control_results.json"),"w") as f:
        json.dump(results,f,indent=1,default=lambda o:None)
    print("\n\nErgebnisse gespeichert -> control_results.json")
