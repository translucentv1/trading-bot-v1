//+------------------------------------------------------------------+
//| add_symbols.mq5 - Symbole finden, hinzufuegen, Historie laden    |
//|                                                                  |
//| Durchsucht ALLE Symbole des Brokers (nicht nur Market Watch),    |
//| identifiziert Indices, Krypto, Metalle/Rohstoffe und fuegt sie   |
//| zum Market Watch hinzu. Loest dann Historie-Download aus.        |
//|                                                                  |
//| Ergebnis wird nach Common\Files\symbols_found.txt geschrieben.   |
//| Ausfuehrung: im MT5 als Script auf beliebigen Chart ziehen.      |
//+------------------------------------------------------------------+
#property copyright "Utility - Symbol-Finder"
#property version   "1.00"
#property script_show_inputs

input bool InpAddToWatch   = true;   // Gefundene Symbole zum Market Watch hinzufuegen
input bool InpLoadHistory  = true;   // Historie-Download ausloesen (D1, 5 Jahre)
input bool InpShowAll      = false;  // ALLE Symbole auflisten (nicht nur Nicht-FX)

//+------------------------------------------------------------------+
void OnStart()
  {
   int total = SymbolsTotal(false); // false = ALLE beim Broker, nicht nur Market Watch
   int inWatch = SymbolsTotal(true);

   Print("=== Symbol-Finder ===");
   Print("Broker-Symbole gesamt: ", total);
   Print("Davon in Market Watch: ", inWatch);

   // Kategorien sammeln
   string indices[];
   string crypto[];
   string metals[];
   string energy[];
   string other[];
   string forex[];

   for(int i = 0; i < total; i++)
     {
      string name = SymbolName(i, false);
      if(name == "") continue;

      // Kategorie bestimmen via SYMBOL_SECTOR / SYMBOL_INDUSTRY
      // Alternativ: SYMBOL_PATH gibt oft "Forex\", "Crypto\", "Indices\" etc.
      string path = "";
      if(!SymbolInfoString(name, SYMBOL_PATH, path)) path = "";

      ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(name, SYMBOL_TRADE_CALC_MODE);

      // Klassifizierung
      bool isFX = (StringFind(path, "Forex") >= 0) || (calcMode == SYMBOL_CALC_MODE_FOREX);
      bool isIndex = (StringFind(path, "Ind") >= 0) || (StringFind(path, "CFD") >= 0)
                     || (StringFind(name, "500") >= 0) || (StringFind(name, "NAS") >= 0)
                     || (StringFind(name, "GER") >= 0) || (StringFind(name, "DAX") >= 0)
                     || (StringFind(name, "JPN") >= 0) || (StringFind(name, "UK1") >= 0)
                     || (StringFind(name, "US30") >= 0) || (StringFind(name, "US500") >= 0)
                     || (StringFind(name, "USTEC") >= 0) || (StringFind(name, "DJ") >= 0)
                     || (StringFind(name, "SPX") >= 0) || (StringFind(name, "NDX") >= 0);
      bool isCrypto = (StringFind(path, "Crypto") >= 0) || (StringFind(path, "crypto") >= 0)
                      || (StringFind(name, "BTC") >= 0) || (StringFind(name, "ETH") >= 0)
                      || (StringFind(name, "XRP") >= 0) || (StringFind(name, "SOL") >= 0)
                      || (StringFind(name, "DOGE") >= 0) || (StringFind(name, "LTC") >= 0);
      bool isMetal = (StringFind(path, "Metal") >= 0) || (StringFind(name, "XAU") >= 0)
                     || (StringFind(name, "XAG") >= 0) || (StringFind(name, "GOLD") >= 0)
                     || (StringFind(name, "SILVER") >= 0);
      bool isEnergy = (StringFind(path, "Energ") >= 0) || (StringFind(name, "OIL") >= 0)
                      || (StringFind(name, "BRENT") >= 0) || (StringFind(name, "WTI") >= 0)
                      || (StringFind(name, "NGAS") >= 0) || (StringFind(name, "CL") >= 0);

      // Nur handelbare pruefen
      bool tradable = SymbolInfoInteger(name, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED;

      if(isIndex && !isFX)        { ArrayResize(indices, ArraySize(indices)+1); indices[ArraySize(indices)-1] = name; }
      else if(isCrypto && !isFX)  { ArrayResize(crypto, ArraySize(crypto)+1); crypto[ArraySize(crypto)-1] = name; }
      else if(isMetal)            { ArrayResize(metals, ArraySize(metals)+1); metals[ArraySize(metals)-1] = name; }
      else if(isEnergy)           { ArrayResize(energy, ArraySize(energy)+1); energy[ArraySize(energy)-1] = name; }
      else if(isFX)               { ArrayResize(forex, ArraySize(forex)+1); forex[ArraySize(forex)-1] = name; }
      else                        { ArrayResize(other, ArraySize(other)+1); other[ArraySize(other)-1] = name; }
     }

   // Ergebnis ausgeben und in Datei schreiben
   int h = FileOpen("symbols_found.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h == INVALID_HANDLE) { Print("FEHLER: Kann Ergebnis-Datei nicht oeffnen!"); return; }

   FileWrite(h, "=== Symbol-Finder Ergebnis ===");
   FileWrite(h, "Broker: " + AccountInfoString(ACCOUNT_SERVER));
   FileWrite(h, "Broker-Symbole gesamt: " + IntegerToString(total));
   FileWrite(h, "");

   WriteCategory(h, "INDICES / CFDs", indices);
   WriteCategory(h, "KRYPTO", crypto);
   WriteCategory(h, "METALLE", metals);
   WriteCategory(h, "ENERGIE", energy);
   if(InpShowAll)
     {
      WriteCategory(h, "FOREX", forex);
      WriteCategory(h, "SONSTIGE", other);
     }

   // Nicht-FX zum Market Watch hinzufuegen + Historie laden
   int added = 0;
   if(InpAddToWatch)
     {
      FileWrite(h, "");
      FileWrite(h, "=== Zum Market Watch hinzugefuegt ===");
      added += AddSymbols(h, indices, InpLoadHistory);
      added += AddSymbols(h, crypto, InpLoadHistory);
      added += AddSymbols(h, metals, InpLoadHistory);
      added += AddSymbols(h, energy, InpLoadHistory);
      FileWrite(h, "Gesamt hinzugefuegt: " + IntegerToString(added));
     }

   FileClose(h);
   Print("=== Fertig. ", ArraySize(indices), " Indices, ", ArraySize(crypto), " Krypto, ",
         ArraySize(metals), " Metalle, ", ArraySize(energy), " Energie gefunden. ",
         added, " zum Market Watch hinzugefuegt. Ergebnis: Common\\Files\\symbols_found.txt ===");
  }

//+------------------------------------------------------------------+
void WriteCategory(int fileHandle, string label, string &arr[])
  {
   int sz = ArraySize(arr);
   FileWrite(fileHandle, label + " (" + IntegerToString(sz) + "):");
   Print(label, " (", sz, "):");
   for(int i = 0; i < sz; i++)
     {
      string info = arr[i];
      // Zusatzinfos
      double point = SymbolInfoDouble(arr[i], SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(arr[i], SYMBOL_DIGITS);
      double minLot = SymbolInfoDouble(arr[i], SYMBOL_VOLUME_MIN);
      bool inWatch = SymbolInfoInteger(arr[i], SYMBOL_SELECT) != 0;
      string tradeModeStr = "";
      long tradeMode = SymbolInfoInteger(arr[i], SYMBOL_TRADE_MODE);
      if(tradeMode == SYMBOL_TRADE_MODE_DISABLED) tradeModeStr = " [DISABLED]";
      else if(tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) tradeModeStr = " [CLOSE-ONLY]";

      info += " | digits=" + IntegerToString(digits) + " minLot=" + DoubleToString(minLot,2)
              + (inWatch ? " [MW]" : "") + tradeModeStr;

      FileWrite(fileHandle, "  " + info);
      Print("  ", info);
     }
   FileWrite(fileHandle, "");
  }

//+------------------------------------------------------------------+
int AddSymbols(int fileHandle, string &arr[], bool loadHist)
  {
   int count = 0;
   for(int i = 0; i < ArraySize(arr); i++)
     {
      // Nur handelbare
      long tradeMode = SymbolInfoInteger(arr[i], SYMBOL_TRADE_MODE);
      if(tradeMode == SYMBOL_TRADE_MODE_DISABLED) continue;

      bool ok = SymbolSelect(arr[i], true);
      if(ok)
        {
         count++;
         FileWrite(fileHandle, "  + " + arr[i]);
         Print("  + Market Watch: ", arr[i]);

         if(loadHist)
           {
            // Historie-Download ausloesen durch CopyRates-Aufruf
            MqlRates rates[];
            datetime from = D'2020.01.01';
            datetime to   = TimeCurrent();
            int copied = CopyRates(arr[i], PERIOD_D1, from, to, rates);
            if(copied > 0)
               FileWrite(fileHandle, "    Historie: " + IntegerToString(copied) + " D1-Kerzen geladen");
            else
               FileWrite(fileHandle, "    Historie: Download angestossen (evtl. noch nicht verfuegbar)");
            Print("    ", arr[i], " D1 Historie: ", copied, " Kerzen");
           }
        }
     }
   return(count);
  }
//+------------------------------------------------------------------+
