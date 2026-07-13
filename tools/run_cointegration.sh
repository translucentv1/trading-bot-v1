#!/bin/bash
# Fuehrt den Cointegration-Pre-Check (EA) fuer alle 15 Paar-Kombinationen
# des 6er-Korbs im MT5 Strategy Tester aus. Antwort auf Phase 1.
DATA_DIR="/c/Users/phili/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075"
TERMINAL="/c/Program Files/MetaTrader 5/terminal64.exe"
CFG_DIR="$DATA_DIR/Tester/config"
mkdir -p "$CFG_DIR"

# 6er-Korb
SYMBOLS=(EURUSD GBPUSD USDJPY AUDUSD USDCAD XAUUSD)

# 15 Kombinationen (i<j) generieren
PAIRS=()
for ((i=0; i<${#SYMBOLS[@]}; i++)); do
  for ((j=i+1; j<${#SYMBOLS[@]}; j++)); do
    PAIRS+=("${SYMBOLS[$i]}|${SYMBOLS[$j]}")
  done
done

echo "=== ${#PAIRS[@]} Paar-Kombinationen ==="
for p in "${PAIRS[@]}"; do echo "  $p"; done
echo ""

# Alte Ergebnisdateien loeschen
rm -f "$DATA_DIR/Tester/Common/Files/coin_"*.txt 2>/dev/null
rm -f "$DATA_DIR/MQL5/Files/coin_"*.txt 2>/dev/null
# Common Files Ordner
COMMON_FILES="/c/Users/phili/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
rm -f "$COMMON_FILES/coin_"*.txt 2>/dev/null

COUNT=0
for pair in "${PAIRS[@]}"; do
  COUNT=$((COUNT+1))
  SYMA="${pair%|*}"
  SYMB="${pair#*|}"
  CFG="$CFG_DIR/coin_${SYMA}_${SYMB}.ini"
  SETFILE="$CFG_DIR/coin_${SYMA}_${SYMB}.set"

  # .set Datei (EA Parameter): SymbolA=leer (Tester-Symbol), SymbolB=B
  cat > "$SETFILE" << EOF
InpSymbolA=||
InpSymbolB=$SYMB||GBPUSD
InpUseLog=1
InpTF=PERIOD_H1||
InpLookback=30000||30000||1||65535
InpADFLag=1||1||0||5
InpCrit1pct=-3.43
InpCrit5pct=-2.86
InpCrit10pct=-2.57
EOF

  # .ini Datei (Tester Config)
  cat > "$CFG" << EOF
[Common]
Login=0
Password=
Server=
Symbol=${SYMA}
Period=H1
Deposit=10000
Currency=EUR
Leverage=30
UseLocal=1
UseRemote=0
RemoteCache=0
Optimization=0
Model=1
ExecutionMode=0
ForwardMode=0
FromDate=2022.01.01
ToDate=2026.07.11
Deposit=10000
Currency=EUR
Leverage=30
Visual=0

[Tester]
Expert=cointegration_check_ea
Symbol=${SYMA}
Period=H1
Optimization=0
Model=1
FromDate=2022.01.01
ToDate=2026.07.11
ExecutionMode=0
ForwardMode=0
ForwardDate=0
Report=coin_report
ReplaceReport=1
ShutdownTerminal=1
UseLocal=1
UseRemote=0
RemoteCache=0
Deposit=10000
Currency=EUR
Leverage=30
Visual=0
${SETFILE##*/}=coin_${SYMA}_${SYMB}.set
EOF

  echo "[$COUNT/15] Teste $SYMA ~ $SYMB ..."
  "$TERMINAL" /portable /config:"${CFG##*/}" 2>/dev/null
  sleep 6
done

echo ""
echo "=== Ergebnisse sammeln ==="
sleep 3
if [ -d "$COMMON_FILES" ]; then
  echo "--- Common/Files ---"
  cat "$COMMON_FILES"/coin_*.txt 2>/dev/null | sort
fi
echo ""
echo "--- MQL5/Files (falls dorthin) ---"
cat "$DATA_DIR/MQL5/Files"/coin_*.txt 2>/dev/null | sort
