# 03 -- MT5-Backtest-Automatisierung: headless / skriptbar?

Type: research
Status: resolved
Blocked by: -

## Question

Wie weit laesst sich der MT5-Strategy-Tester automatisieren, damit Backtests nicht
mehr von Hand im MetaEditor/Tester geklickt werden muessen?
- Kann `terminal64.exe` per Kommandozeile mit einer `.ini`-Konfiguration einen
  Tester-Lauf headless starten und einen Report (XML/HTML) ausgeben?
- Optimierungslaeufe (Parameter-Sweeps) automatisiert -- und wie kommt man an die
  Ergebnis-Tabelle (`.opt`-Datei / Report) heran?
- Wie kompiliert man `.mq5` -> `.ex5` per CLI (`metaeditor64.exe /compile`)?
- Grenzen: Demo-Server-Abhaengigkeit, GUI-Zwang, Lizenz/Automatisierungslimits.
- Was davon ist auf Windows-Solo-Setup realistisch skriptbar (PowerShell/Python)?

Ergebnis bestimmt den machbaren Automatisierungsgrad im Spielplan (Werkzeuge/Infra)
und graduiert den Nebel-Punkt "Automatisierungs-Ausbau des Backtest-Laufs".

## Answer

Kurzfazit: Headless-CLI-Backtest per `terminal64.exe /config:...ini` ist offiziell
unterstuetzt und JA moeglich. Kompilieren per `metaeditor64.exe /compile` ebenfalls.
Ein voll ununterbrochener End-to-End-Loop (kompilieren -> testen -> Report einlesen)
ist per PowerShell/Python skriptbar. Zwei Einschraenkungen bleiben: (1) ein echter
"headless ohne GUI"-Modus existiert nicht -- das Terminal startet immer ein Fenster,
laeuft aber ohne Klicks autonom durch; (2) Backtests brauchen Verlaufsdaten vom
Broker-Server, d.h. eine funktionierende Login-Verbindung (Demo-Server-Abhaengigkeit).

### (a) Headless-Backtest per terminal64.exe + .ini -- JA

Aufruf:

    "C:\Program Files\MetaTrader 5\terminal64.exe" /config:C:\pfad\backtest.ini

Wichtige Flags:
- `/config:<datei.ini>` -- Konfigurationsdatei (Pflicht fuer Automatik).
- `/portable` -- Portable-Modus (Datenordner neben der EXE statt in %APPDATA%;
  praktisch fuer reproduzierbare Solo-Setups, sauber versionierbar).
- `/login:<nummer>` -- Konto erzwingen (sonst aus [Tester]/Login oder [Common]).

Beispiel-.ini (`backtest.ini`, ANSI/UTF-16 speichern -- MT5 mag kein UTF-8-BOM):

    [Tester]
    Expert=ema_mtf_v3          ; Pfad RELATIV zu MQL5\Experts, OHNE .ex5, OHNE Pfad-Praefix
    Symbol=EURUSD
    Period=H1
    Model=1                    ; 0=jeder Tick, 1=1-Min-OHLC, 2=nur Eroeffnung, 3=Mathe, 4=echte Ticks
    ExecutionMode=0            ; Ausfuehrungsverzoegerung (0 = keine)
    Optimization=0             ; 0=aus (einzelner Backtest)
    FromDate=2024.01.01        ; Format YYYY.MM.DD
    ToDate=2024.06.30
    ForwardMode=0              ; 0=aus, 1=1/2, 2=1/3, 3=1/4, 4=eigenes Datum (ForwardDate=...)
    Deposit=10000
    Currency=USD
    Leverage=100
    Report=C:\reports\ema_mtf_v3   ; Ausgabepfad OHNE Endung -> erzeugt .xml (+ optional .html)
    ReplaceReport=1            ; 1 = vorhandenen Report ueberschreiben
    UseLocal=1                 ; lokale Testagenten nutzen
    Visual=0                   ; 0 = kein visueller Modus
    ShutdownTerminal=1         ; Terminal nach Lauf automatisch schliessen (Pflicht fuer Skript-Loop!)

    [TesterInputs]
    ; EA-Eingaben ueberschreiben (sonst .set-Defaults). Format value||start||step||stop||flag
    InpFastEMA=12
    InpSlowEMA=26

Report-Ausgabe: `Report=<pfad>` schreibt einen XML-Report (in aktuellen Builds
`.xml`, per XML gut mit Python/pandas parsebar). `ShutdownTerminal=1` ist der
Schluessel fuer Automatik -- ohne ihn bleibt das Terminal offen und der Skript-Loop
haengt. Der [Common]-Block (Login/Server/Password) kann in dieselbe .ini, damit sich
das Terminal fuer Datenzugriff selbst anmeldet.

### (b) Optimierung / Parameter-Sweeps -- JA

In [Tester]:
- `Optimization=1` = langsame vollstaendige Durchrechnung (alle Kombinationen)
- `Optimization=2` = schnelle genetische Optimierung
- `Optimization=3` = alle Symbole der Marktuebersicht
- `OptimizationCriterion=` 0=Saldo max, 1=Gewinnfaktor, 2=Erwartungswert,
  3=Drawdown min, 4=Recovery, 5=Sharpe, 6=eigenes Kriterium (OnTester).

Die zu variierenden Parameter in [TesterInputs] mit Sweep-Syntax:

    InpSlowEMA=26||10||2||60||Y     ; value || start || step || stop || Y(=optimieren)/N

Ergebnis-Tabelle: Die Optimierung schreibt einen `.opt`-Cache (binaer, im
`MQL5\Tester\...cache\`-Ordner -- vom Terminal selbst als Wiederverwendungs-Cache
gedacht, kein bequemes Austauschformat). Praktisch nutzbar: der `Report=`-Parameter
liefert bei Optimierung eine XML-Ergebnistabelle mit einer Zeile pro
Parameter-Kombination inkl. Kennzahlen. Diese XML ist die realistische Quelle fuer
die Auswertung per Python. (Die `.opt`-Datei laesst sich zwar im Tester wieder
oeffnen, aber programmatisch ist der XML-Report der Weg.)

### (c) Kompilieren .mq5 -> .ex5 per CLI -- JA

    "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"C:\...\MQL5\Experts\ema_mtf_v3.mq5" /log

Keys:
- `/compile:"<datei-oder-ordner>"` -- Einzeldatei ODER Ordner (Massenkompilierung
  aller Quellen im Ordner; Unterordner ausgenommen).
- `/log` -- schreibt `<quellname>.log` neben die Quelldatei (bzw. `/log:"pfad.txt"`).
- `/include:"<MQL5-ordner>"` -- Include-Basis, falls ausserhalb des Arbeitsordners.
- `/s` -- reine Syntaxpruefung ohne Kompilat.

Fallstricke: metaeditor64.exe kehrt zwar zurueck, liefert aber KEINEN verlaesslichen
Exit-Code fuer Fehler -- man muss die `.log`-Datei parsen (auf "0 errors"/Fehlerzeilen
pruefen). Bei sehr grossen modularen Projekten wurde von stillen Fehlschlaegen
berichtet. Der Aufruf blockiert nicht immer sauber; ggf. `Start-Process -Wait` in
PowerShell nutzen und danach das Log auswerten.

### (d) Grenzen

- Kein echter Headless-/Server-Modus: Das Terminal ist eine GUI-App und oeffnet immer
  ein Fenster. Es laeuft aber ohne Interaktion durch (mit ShutdownTerminal=1). Fuer
  reine Serverlaeufe braeuchte man eine RDP-/Session-0-Umgebung; auf einem
  Solo-Desktop laeuft es einfach im Vordergrund/Hintergrundfenster.
- Broker-/Demo-Server-Abhaengigkeit: Backtests brauchen Kursverlauf. Fehlende Daten
  werden beim Testlauf vom Server nachgeladen -> Login noetig. Faellt der Demo-Server
  aus, kann der Lauf ohne Daten leer/fehlerhaft sein (deckt sich mit dem bekannten
  MEMORY-Hinweis "Nutzer klickt nur bei Demo-Server-Aussetzern").
- EA-Pfad: `Expert=` ist relativ zu `MQL5\Experts` und ohne Endung -- die .ex5 muss
  in der Sandbox liegen (kein beliebiger Pfad).
- Kein offizieller Fehler-Exit-Code beim Compile -> Log-Parsing zwingend.
- .opt-Optimierungscache ist binaer/undokumentiert -> XML-Report als Datenquelle.
- Optimization=3 (alle Symbole) per CLI wird in Foren als unzuverlaessig gemeldet.

### (e) Realistisch skriptbar auf Windows-Solo (PowerShell/Python)

Voll machbar und empfohlen -- ein Ein-Klick-Skript-Loop:
1. PowerShell: `metaeditor64.exe /compile:... /log` -> Log auf Fehler pruefen.
2. .ini generieren (Python/PowerShell aus Vorlage; Symbol/Zeitraum/Inputs einsetzen).
3. `Start-Process terminal64.exe -ArgumentList '/config:backtest.ini' -Wait`
   (mit ShutdownTerminal=1 kehrt der Prozess nach dem Lauf zurueck).
4. XML-Report mit Python (xml.etree/pandas) einlesen -> Kennzahlen ziehen ->
   direkt als Zeile in `backtests.csv` schreiben und `tools/validate_backtests.py`
   anstossen.

Empfohlener Automatisierungsgrad: **hoch -- "ein Kommando, Terminal blitzt kurz auf,
CSV-Zeile faellt raus"**. Nicht 100% unsichtbar (GUI-Fenster + Login-Bedarf bleiben),
aber die manuellen Tester-Klicks entfallen komplett. Der Nebel-Punkt kann von
"unklar" auf "machbar, mittlerer Bauaufwand" graduiert werden: Kernstueck ist ein
`run_backtest.ps1` + `parse_report.py`, das kompilieren, .ini-Vorlage fuellen, Lauf
starten und XML->CSV erledigt. Einzige verbleibende Handarbeit: bei Demo-Server-
Aussetzern erneut anstossen.

### Quellen

- Platform Start / .ini-Konfiguration ([Tester]-Sektion, Flags):
  https://www.metatrader5.com/en/terminal/help/start_advanced/start
- MetaEditor CLI (/compile, /log, /include, /s):
  https://www.metatrader5.com/en/metaeditor/help/beginning/integration_ide
- Strategy Tester (Modelle, Ablauf):
  https://www.metatrader5.com/en/terminal/help/algotrading/testing
- Strategy Optimization (Optimierungsmodi, Kriterien):
  https://www.metatrader5.com/en/terminal/help/algotrading/strategy_optimization
- Artikel "LifeHack for trader: four backtests are better than one" (.ini-Beispiele,
  Model-/Report-Keys): https://www.mql5.com/en/articles/2552
- Forum: Running Strategy Tester from Batch File (praktische .ini/[TesterInputs]):
  https://www.mql5.com/en/forum/457213
- Forum: Metatrader 5 command line backtesting:
  https://www.mql5.com/en/forum/462397
- Forum: Optimization=3 per CLI (Einschraenkung):
  https://www.mql5.com/en/forum/510025
