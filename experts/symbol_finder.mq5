//+------------------------------------------------------------------+
//| symbol_finder.mq5 - Als EA im Tester: Symbole finden + laden     |
//|                                                                  |
//| Laueft im Strategy Tester (1 Bar genuegt), listet alle           |
//| Broker-Symbole auf und fuegt Nicht-FX zum Market Watch hinzu.    |
//| ACHTUNG: SymbolSelect() im Tester funktioniert NICHT zum         |
//| Hinzufuegen. Dieser EA LISTET daher nur auf, was verfuegbar ist. |
//| Das Hinzufuegen muss dann ueber das Script laufen.               |
//|                                                                  |
//| Ergebnis: Common\Files\symbols_found.txt                         |
//+------------------------------------------------------------------+
#property copyright "Utility - Symbol-Finder"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
int OnInit()
  {
   int total = SymbolsTotal(false);
   int inWatch = SymbolsTotal(true);

   Print("=== Symbol-Finder (EA-Modus) ===");
   Print("Broker-Symbole gesamt: ", total);
   Print("Davon in Market Watch: ", inWatch);

   int h = FileOpen("symbols_found.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h == INVALID_HANDLE) { Print("FEHLER: Datei nicht oeffnbar!"); return(INIT_FAILED); }

   FileWrite(h, "=== Symbol-Finder Ergebnis ===");
   FileWrite(h, "Broker: " + AccountInfoString(ACCOUNT_SERVER));
   FileWrite(h, "Symbole gesamt: " + IntegerToString(total));
   FileWrite(h, "In Market Watch: " + IntegerToString(inWatch));
   FileWrite(h, "");

   for(int i = 0; i < total; i++)
     {
      string name = SymbolName(i, false);
      if(name == "") continue;

      string path = "";
      SymbolInfoString(name, SYMBOL_PATH, path);

      int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
      double minLot = SymbolInfoDouble(name, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(name, SYMBOL_VOLUME_MAX);
      bool inMW = SymbolInfoInteger(name, SYMBOL_SELECT) != 0;
      long tradeMode = SymbolInfoInteger(name, SYMBOL_TRADE_MODE);
      string tmStr = "";
      if(tradeMode == SYMBOL_TRADE_MODE_DISABLED) tmStr = "DISABLED";
      else if(tradeMode == SYMBOL_TRADE_MODE_FULL) tmStr = "FULL";
      else if(tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) tmStr = "CLOSE_ONLY";
      else tmStr = "OTHER(" + IntegerToString(tradeMode) + ")";

      ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(name, SYMBOL_TRADE_CALC_MODE);
      string cmStr = "";
      if(calcMode == SYMBOL_CALC_MODE_FOREX) cmStr = "FX";
      else if(calcMode == SYMBOL_CALC_MODE_CFD) cmStr = "CFD";
      else if(calcMode == SYMBOL_CALC_MODE_CFDINDEX) cmStr = "CFD_IDX";
      else if(calcMode == SYMBOL_CALC_MODE_CFDLEVERAGE) cmStr = "CFD_LEV";
      else if(calcMode == SYMBOL_CALC_MODE_EXCH_STOCKS) cmStr = "STOCK";
      else if(calcMode == SYMBOL_CALC_MODE_EXCH_FUTURES) cmStr = "FUT";
      else cmStr = "MODE_" + IntegerToString((int)calcMode);

      string line = name + " | path=" + path + " | calc=" + cmStr + " | digits=" + IntegerToString(digits)
                    + " | minLot=" + DoubleToString(minLot,2) + " | trade=" + tmStr
                    + (inMW ? " | [MW]" : "");

      FileWrite(h, line);
      Print(line);
     }

   FileClose(h);
   Print("=== Fertig. Datei: Common\\Files\\symbols_found.txt ===");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnTick() { /* Nichts - EA nur fuer OnInit-Scan */ }
void OnDeinit(const int reason) { }
//+------------------------------------------------------------------+
