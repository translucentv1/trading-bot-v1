import csv, math, sys, os
from collections import defaultdict

PATH = "backtests.csv"
WRITE = "--write" in sys.argv

def f(x):
    try: return float(x)
    except (ValueError, TypeError): return None

rows = list(csv.DictReader(open(PATH, encoding="utf-8"), delimiter=";"))

# 1. N pro Strategie-Familie zählen (alle Läufe zählen als Trial, auch wf-is, wf-oos etc.)
strat_counts = defaultdict(int)
for r in rows:
    strat = r.get("strategie", "").strip()
    if strat:
        strat_counts[strat] += 1

print("=== Deflated Sharpe Ratio (DSR) ===")
print("Erwarteter maximaler Z-Score (Hürde) = sqrt(2 * ln(N))")
for strat, N in strat_counts.items():
    hurdle = math.sqrt(2 * math.log(N)) if N > 1 else 0.0
    print(f"Strategie: {strat:15} | N={N:<4} | Hürde Z={hurdle:.2f}")

fixed = 0
for r in rows:
    z = f(r.get("z_score"))
    strat = r.get("strategie", "").strip()
    if z is not None and strat in strat_counts:
        N = strat_counts[strat]
        hurdle = math.sqrt(2 * math.log(N)) if N > 1 else 0.0
        dsr_val = z - hurdle
        
        # Nur schreiben wenn sich der Wert ändert oder leer ist
        old_dsr = f(r.get("dsr"))
        if old_dsr is None or abs(old_dsr - dsr_val) > 0.02:
            if WRITE:
                r["dsr"] = f"{dsr_val:.2f}"
                fixed += 1

# 2. Walk-Forward Efficiency (WFE) aggregieren
print("\n=== Walk-Forward Efficiency (WFE) ===")
# Gruppieren nach Hypothese + Zyklus
wf_runs = defaultdict(dict)
for r in rows:
    hypo = r.get("hypothese", "").strip()
    zyk = r.get("wf_zyklus", "").strip()
    phase = r.get("phase", "").strip()
    z = f(r.get("z_score"))
    
    if hypo and zyk and phase in ("wf-is", "wf-oos") and z is not None:
        key = f"{hypo} (Zyklus {zyk})"
        wf_runs[key][phase] = z

for key, phases in wf_runs.items():
    z_is = phases.get("wf-is")
    z_oos = phases.get("wf-oos")
    
    if z_is is not None and z_oos is not None:
        if z_is <= 0:
            wfe_str = "N/A (IS <= 0)"
        else:
            wfe = z_oos / z_is
            wfe_str = f"{wfe*100:.1f}%"
        print(f"{key:35} | IS: {z_is:5.2f} | OOS: {z_oos:5.2f} | WFE: {wfe_str}")

if not wf_runs:
    print("Keine vollständigen Walk-Forward Zyklen gefunden (IS + OOS).")

if WRITE and fixed > 0:
    tmp = PATH + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as out:
        wtr = csv.DictWriter(out, fieldnames=rows[0].keys(), delimiter=";")
        wtr.writeheader()
        wtr.writerows(rows)
    os.replace(tmp, PATH)
    print(f"\n{fixed} DSR Werte neu berechnet und geschrieben.")
elif fixed > 0:
    print(f"\n{fixed} DSR Werte müssten aktualisiert werden (nutze --write zum Speichern).")
else:
    print("\nAlle DSR Werte sind aktuell.")
