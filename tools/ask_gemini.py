# Ruft Google Gemini per API auf - "Gemini als Sub-Agent" fuer Planung
# und Analyse. Automatisiert den bisherigen manuellen AI-Studio-Handoff:
# Claude Code delegiert eine Denk-/Planungsaufgabe an Gemini und liest
# nur die Antwort zurueck. Gemini plant/analysiert - implementiert NICHT
# (gleiche Rolle wie AI Studio; Code/Git/Dateien bleiben bei Claude Code).
#
# Nur Standard-Bibliothek - kein pip install noetig.
#
# API-Key: NIEMALS im Code. Wird aus .env gelesen (Zeile:
#   GEMINI_API_KEY=dein_key ). .env ist in .gitignore. Key gratis holen
# (ohne Kreditkarte) in Google AI Studio: https://aistudio.google.com/apikey
#
# ACHTUNG Datenschutz: Im Free-Tier darf Google Prompts UND Antworten zur
# Produktverbesserung auswerten. Also keine Zugangsdaten, keine sensiblen
# Daten senden - nur Projekt-/Strategie-Fragen (die sind ohnehin oeffentlich
# im Repo).
#
# Token-Nutzen: Grosse Eingaben (--file) gehen an Gemini, nicht in den
# Claude-Kontext. Ideal, wenn Gemini viel Text verarbeiten und nur eine
# kurze Antwort zurueckgeben soll.
#
# Beispiele:
#   python tools/ask_gemini.py "Erklaere Walk-Forward-Efficiency in 3 Saetzen"
#   python tools/ask_gemini.py "Bewerte den Projektstand" --file KONTEXT.md
#   python tools/ask_gemini.py "Fasse zusammen" --file JOURNAL.md --file hypothesen.md
#   echo "Text..." | python tools/ask_gemini.py -        (Prompt von stdin)
#   python tools/ask_gemini.py "..." --model gemini-3-flash
#
# Optionen:
#   --file PFAD    Datei-Inhalt als Kontext anhaengen (mehrfach moeglich)
#   --model NAME   Standard gemini-flash-latest (Alias -> immer aktuelles
#                  Flash-Modell, bricht nicht bei Versions-Abschaltungen).
#                  Alternativen: gemini-flash-lite-latest (mehr Requests/Tag),
#                  gemini-pro-latest (staerker, weniger Requests/Tag).
#                  Feste Versionen (z. B. gemini-2.5-flash) koennen fuer neue
#                  Accounts gesperrt sein -> lieber die -latest-Aliase.
#   --system TEXT  System-Instruktion (Rolle, z. B. "Du bist Quant-Reviewer")

import json
import os
import sys
import urllib.error
import urllib.request

API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
ENV_PATH = ".env"
ENV_KEY = "GEMINI_API_KEY"
DEFAULT_MODEL = "gemini-flash-latest"


def read_api_key():
    if not os.path.exists(ENV_PATH):
        sys.exit(
            f"FEHLER: {ENV_PATH} nicht gefunden. Lege sie an mit der Zeile:\n"
            f"  {ENV_KEY}=dein_key\n"
            "Key gratis (ohne Kreditkarte): https://aistudio.google.com/apikey"
        )
    for line in open(ENV_PATH, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, _, value = line.partition("=")
        if name.strip() == ENV_KEY:
            key = value.strip().strip('"').strip("'")
            if key:
                return key
    sys.exit(f"FEHLER: {ENV_KEY} steht nicht (oder leer) in {ENV_PATH}.")


def parse_args(argv):
    opts = {"prompt": None, "files": [], "model": DEFAULT_MODEL, "system": None}
    if not argv or argv[0] in ("-h", "--help"):
        sys.exit(
            'Aufruf: python tools/ask_gemini.py "Frage" [--file PFAD] '
            "[--model NAME] [--system TEXT]\n"
            '  "-" als Frage liest den Prompt von stdin.'
        )
    opts["prompt"] = argv[0]
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--file" and i + 1 < len(argv):
            opts["files"].append(argv[i + 1]); i += 2
        elif a == "--model" and i + 1 < len(argv):
            opts["model"] = argv[i + 1]; i += 2
        elif a == "--system" and i + 1 < len(argv):
            opts["system"] = argv[i + 1]; i += 2
        else:
            sys.exit(f"Unbekannte oder unvollstaendige Option: {a}")
    return opts


def build_prompt(opts):
    prompt = opts["prompt"]
    if prompt == "-":
        prompt = sys.stdin.read()
    parts = [prompt]
    for path in opts["files"]:
        if not os.path.exists(path):
            sys.exit(f"FEHLER: --file nicht gefunden: {path}")
        with open(path, encoding="utf-8") as fh:
            parts.append(f"\n\n--- Datei: {path} ---\n{fh.read()}")
    return "".join(parts)


def call_gemini(text, opts, api_key):
    body = {"contents": [{"parts": [{"text": text}]}]}
    if opts["system"]:
        body["systemInstruction"] = {"parts": [{"text": opts["system"]}]}
    data = json.dumps(body).encode("utf-8")
    url = API.format(model=opts["model"])
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("x-goog-api-key", api_key)  # Key im Header, nicht in URL
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")
        sys.exit(f"FEHLER {e.code} von Gemini: {detail}")


def extract_text(data):
    cands = data.get("candidates")
    if not cands:
        fb = data.get("promptFeedback", {})
        sys.exit(f"FEHLER: keine Antwort (evtl. blockiert). Feedback: {fb}")
    parts = cands[0].get("content", {}).get("parts", [])
    text = "".join(p.get("text", "") for p in parts).strip()
    if not text:
        reason = cands[0].get("finishReason", "unbekannt")
        sys.exit(f"FEHLER: leere Antwort (finishReason={reason}).")
    return text


def main():
    opts = parse_args(sys.argv[1:])
    api_key = read_api_key()
    text = build_prompt(opts)
    data = call_gemini(text, opts, api_key)
    print(extract_text(data))


if __name__ == "__main__":
    main()
