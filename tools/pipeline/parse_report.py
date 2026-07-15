# parse_report.py -- liest einen MT5-Strategy-Tester-Report (HTML/XML) und haengt
# EINE Zeile an backtests.csv an. Teil der Automatisierungs-Pipeline (Ticket 08).
#
# Prinzip (Ticket 08): "laut abbrechen statt Muell schreiben".
#   - Plausibilitaetscheck: Report muss Trades > 0 enthalten, sonst KEINE CSV-Zeile.
#   - Pflichtfelder fehlen -> Exit 1 (Fehler), nichts geschrieben.
#   - Atomar: erst .tmp schreiben, dann ersetzen (nie halbe CSV).
#
# Kennzahlen kommen aus dem Report; die Metadaten (id, symbol, hypothese, phase, ...)
# liefert der Orchestrator run_backtest.ps1 als --meta <json>.
#
# WICHTIG (ehrlich): Die Label-Zuordnung unten (LABELS) ist gegen die STANDARD-
# MT5-Reportstruktur gebaut, EN + DE. Weicht dein Report ab (andere Sprache/Version),
# ist LABELS die EINE Stelle zum Anpassen -- ein echter Report als Muster genuegt.
# Robustere Alternative fuer spaeter: Kennzahlen im EA per OnTester() in eine
# strukturierte Datei schreiben und die hier lesen (kein HTML-Scraping). Siehe README.

import argparse, csv, json, os, re, sys, html

# Spaltenreihenfolge MUSS zum Header von backtests.csv passen.
COLUMNS = [
    "id", "datum", "ea_version", "zeitraum", "symbol", "exec_tf", "bias_tf",
    "richtung", "strategie", "net_profit", "profit_factor", "sharpe", "dd_pct",
    "trades", "win_rate_pct", "avg_win", "avg_loss", "max_loss_streak",
    "risk_realized_pct", "z_score", "hypothese", "phase", "wf_zyklus", "dsr", "fazit",
]

# Aus dem Report gelesene Kennzahlen. Metadaten kommen aus --meta.
# (True = Pflichtfeld: fehlt es -> lauter Abbruch.)
REPORT_FIELDS = {
    "net_profit":     True,
    "profit_factor":  True,
    "trades":         True,
    "sharpe":         False,
    "dd_pct":         False,
    "win_rate_pct":   False,
    "avg_win":        False,
    "avg_loss":       False,
    "max_loss_streak": False,
}

# Label-Varianten (EN | DE), klein geschrieben und UMLAUT-NORMALISIERT (ue/oe/ae/ss).
# Gegen echten deutschen MT5-Report (UTF-16) verifiziert. Erstes Treffer-Label gewinnt;
# die Reihenfolge im Text entscheidet bei aehnlichen Labels (spezifischste zuerst egal,
# da die kuerzere Kennzahl im Report vor der "... in Folge"-Variante steht).
LABELS = {
    "net_profit":     ["total net profit", "nettogewinn gesamt", "gesamtnettogewinn"],
    "profit_factor":  ["profit factor", "profitfaktor"],
    "sharpe":         ["sharpe-ratio", "sharpe ratio"],
    "trades":         ["total trades", "gesamtanzahl trades", "trades gesamt"],
    "win_rate_pct":   ["profit trades (% of total)",
                       "gewonnene trades (in % von gesamt)"],
    "avg_win":        ["average profit trade", "durchschnitt gewinntrade",
                       "durchschnittlicher gewinntrade"],
    "avg_loss":       ["average loss trade", "durchschnitt verlusttrade",
                       "durchschnittlicher verlusttrade"],
    "dd_pct":         ["balance drawdown maximal", "rueckgang kontostand maximal",
                       "equity drawdown maximal"],
    "max_loss_streak": ["maximum consecutive losses", "verlusttrades in folge",
                        "maximale verlustserie"],
}

NUM = r"-?\d[\d ]*[.,]?\d*"  # muss mit Ziffer beginnen (nach opt. -); Tausender-Leerzeichen ok


def to_float(s):
    if s is None:
        return None
    s = s.strip().replace(" ", "").replace(" ", "")
    # deutsches Format 1.234,56 -> 1234.56 ; sonst Punkt-Dezimal
    if "," in s and "." in s:
        s = s.replace(".", "").replace(",", ".")
    else:
        s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


UMLAUT = str.maketrans({
    "ä": "ae", "ö": "oe", "ü": "ue", "Ä": "Ae", "Ö": "Oe", "Ü": "Ue", "ß": "ss",
})


def read_report(path):
    # MT5-Reports sind je nach Sprache UTF-16 (deutsch) oder UTF-8. BOM erkennen.
    with open(path, "rb") as f:
        b = f.read()
    if b[:2] in (b"\xff\xfe", b"\xfe\xff"):
        enc = "utf-16"
    elif b[:3] == b"\xef\xbb\xbf":
        enc = "utf-8-sig"
    else:
        enc = "utf-8"
    return b.decode(enc, errors="replace")


def detag(raw):
    # HTML/XML zu Klartext: Tags raus, Entities aufloesen, Umlaute normalisieren,
    # Whitespace vereinheitlichen.
    txt = re.sub(r"<[^>]+>", " ", raw)
    txt = html.unescape(txt).translate(UMLAUT)
    txt = txt.replace(" ", " ")
    return re.sub(r"[ \t]+", " ", txt)


def find_after_label(text, labels):
    # Sucht das erste Label und gibt den unmittelbar folgenden Zahlenblock zurueck.
    low = text.lower()
    for lab in labels:
        i = low.find(lab)
        if i == -1:
            continue
        rest = text[i + len(lab): i + len(lab) + 120]
        m = re.search(NUM, rest)
        if m:
            return m.group(0), rest
    return None, None


def find_percent_in(segment):
    # Extrahiert einen Prozentwert aus "... (5.99%)" o.ae.
    if not segment:
        return None
    m = re.search(r"\(?\s*(" + NUM + r")\s*%\)?", segment)
    return m.group(1) if m else None


def extract(text):
    out = {}
    for field, labels in LABELS.items():
        val, seg = find_after_label(text, labels)
        if field in ("win_rate_pct", "dd_pct"):
            # Prozent aus dem Segment bevorzugen (MT5 zeigt "wert (xx%)").
            pct = find_percent_in(seg)
            out[field] = to_float(pct) if pct is not None else to_float(val)
        elif field in ("max_loss_streak", "trades"):
            out[field] = int(to_float(val)) if to_float(val) is not None else None
        else:
            out[field] = to_float(val)
    return out


def next_id(csv_path):
    if not os.path.exists(csv_path):
        return 1
    mx = 0
    with open(csv_path, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f, delimiter=";"):
            try:
                mx = max(mx, int(r["id"]))
            except (ValueError, KeyError, TypeError):
                pass
    return mx + 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True, help="Pfad zum MT5-Report (HTML/XML)")
    ap.add_argument("--meta", required=True, help="JSON mit Metadaten (symbol, hypothese, ...)")
    ap.add_argument("--csv", default="backtests.csv")
    args = ap.parse_args()

    if not os.path.exists(args.report):
        sys.exit(f"FEHLER: Report nicht gefunden: {args.report} -- nichts geschrieben.")

    text = detag(read_report(args.report))
    meta = json.load(open(args.meta, encoding="utf-8"))

    metrics = extract(text)

    # Plausibilitaet: ohne Trades ist der Lauf kaputt/leer -> lauter Abbruch.
    trades = metrics.get("trades")
    if trades is None or trades <= 0:
        sys.exit("FEHLER: Report enthaelt keine Trades (leer/kaputt?) -- "
                 "KEINE CSV-Zeile geschrieben. Demo-Server/Daten pruefen.")

    # Pflichtfelder pruefen.
    fehlend = [k for k, pflicht in REPORT_FIELDS.items()
               if pflicht and metrics.get(k) is None]
    if fehlend:
        sys.exit(f"FEHLER: Pflicht-Kennzahlen nicht im Report gefunden: {fehlend}. "
                 "LABELS in parse_report.py an das Report-Format anpassen "
                 "(ein echter Report als Muster). Nichts geschrieben.")

    # Zeile bauen: Metadaten + Kennzahlen. risk_realized_pct/z_score/dsr bleiben leer
    # (z_score + risk werden von validate_backtests.py nachgerechnet; dsr spaeter).
    row = {c: "" for c in COLUMNS}
    for k, v in meta.items():
        if k in row:
            row[k] = v
    if not row["id"]:
        row["id"] = next_id(args.csv)
    for k in REPORT_FIELDS:
        v = metrics.get(k)
        if v is not None:
            row[k] = f"{v:.2f}" if isinstance(v, float) else str(v)

    # Header pruefen/erzeugen und atomar anhaengen.
    exists = os.path.exists(args.csv)
    if exists:
        with open(args.csv, encoding="utf-8", newline="") as f:
            header = next(csv.reader(f, delimiter=";"))
        if header != COLUMNS:
            sys.exit(f"FEHLER: CSV-Header weicht ab.\n erwartet: {COLUMNS}\n gefunden: {header}")

    tmp = args.csv + ".tmp"
    # Bestehende Zeilen kopieren + neue anhaengen (atomar via replace).
    old = []
    if exists:
        with open(args.csv, encoding="utf-8", newline="") as f:
            old = list(csv.reader(f, delimiter=";"))
    with open(tmp, "w", encoding="utf-8", newline="") as out:
        w = csv.writer(out, delimiter=";")
        if old:
            w.writerows(old)
        else:
            w.writerow(COLUMNS)
        w.writerow([row[c] for c in COLUMNS])
    os.replace(tmp, args.csv)

    print(f"OK: Zeile id {row['id']} angehaengt "
          f"(net {row['net_profit']}, PF {row['profit_factor']}, {row['trades']} Trades).")


if __name__ == "__main__":
    main()
