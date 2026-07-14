//+------------------------------------------------------------------+
//| phase5_short_check.mq5 - Kann der Broker Aktien SHORTEN?         |
//|                                                                  |
//| Gate-Pruefung fuer Phase 5 (markt-neutral Long/Short).           |
//| Laeuft im Tester (1 Bar), zaehlt je Aktien-Symbol den            |
//| SYMBOL_TRADE_MODE (FULL = long+short, LONGONLY = kein Short).    |
//| Schreibt die Liste der voll handelbaren Aktien nach              |
//| Common\Files\phase5_short_check.csv.                             |
//+------------------------------------------------------------------+
#property copyright "Phase 5 - Shortability-Check"
#property version   "1.00"
#property strict

string TradeModeStr(long tm)
  {
   if(tm==SYMBOL_TRADE_MODE_DISABLED)  return("DISABLED");
   if(tm==SYMBOL_TRADE_MODE_LONGONLY)  return("LONGONLY");
   if(tm==SYMBOL_TRADE_MODE_SHORTONLY) return("SHORTONLY");
   if(tm==SYMBOL_TRADE_MODE_CLOSEONLY) return("CLOSEONLY");
   if(tm==SYMBOL_TRADE_MODE_FULL)      return("FULL");
   return("OTHER("+IntegerToString((int)tm)+")");
  }

int OnInit()
  {
   int total = SymbolsTotal(false);
   int nStock=0, nFull=0, nLong=0, nOther=0;

   int h = FileOpen("phase5_short_check.csv", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h==INVALID_HANDLE) { Print("FEHLER: Datei nicht oeffnbar"); return(INIT_FAILED); }
   FileWrite(h, "symbol;calc;trade_mode;min_lot");

   for(int i=0;i<total;i++)
     {
      string name=SymbolName(i,false);
      if(name=="") continue;
      ENUM_SYMBOL_CALC_MODE cm=(ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(name,SYMBOL_TRADE_CALC_MODE);
      // nur Aktien-artige Instrumente
      bool isStock = (cm==SYMBOL_CALC_MODE_EXCH_STOCKS || cm==SYMBOL_CALC_MODE_CFD);
      if(!isStock) continue;
      long tm=SymbolInfoInteger(name,SYMBOL_TRADE_MODE);
      if(tm==SYMBOL_TRADE_MODE_DISABLED) continue;  // nicht handelbar
      nStock++;
      if(tm==SYMBOL_TRADE_MODE_FULL) nFull++;
      else if(tm==SYMBOL_TRADE_MODE_LONGONLY) nLong++;
      else nOther++;
      string calcS = (cm==SYMBOL_CALC_MODE_EXCH_STOCKS)?"STOCK":"CFD";
      FileWrite(h, name+";"+calcS+";"+TradeModeStr(tm)+";"+
                DoubleToString(SymbolInfoDouble(name,SYMBOL_VOLUME_MIN),2));
     }
   FileWrite(h, "# SUMME handelbare Aktien="+IntegerToString(nStock)+
             " FULL(long+short)="+IntegerToString(nFull)+
             " LONGONLY="+IntegerToString(nLong)+" OTHER="+IntegerToString(nOther));
   FileClose(h);
   Print("Shortability: handelbar=",nStock," FULL=",nFull," LONGONLY=",nLong," OTHER=",nOther);
   return(INIT_SUCCEEDED);
  }

void OnTick() {}
void OnDeinit(const int reason) {}
//+------------------------------------------------------------------+
