//+------------------------------------------------------------------+
//| basket_data_collector.mq5                                        |
//+------------------------------------------------------------------+
#property copyright "Utility - Datensammlung"
#property version   "1.00"
#property strict

int OnInit()
  {
   Print("=== Basket Data Collector ===");
   
   string symbols[] = {"AAPL", "AMD", "AMZN", "AVGO", "ADBE", "ABNB", "AXP", "ABT", "AIG", "AEP"};
   
   // Wir schreiben in Common\Files, damit es auch im Tester-Modus sofort verfuegbar ist.
   int h = FileOpen("basket_data.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h == INVALID_HANDLE) 
     { 
      Print("FEHLER: Datei nicht oeffnbar!"); 
      return(INIT_FAILED); 
     }

   FileWrite(h, "SYMBOL|SPREAD|TICK_VALUE|CONTRACT_SIZE|WIN_A_2022_TICKS|WIN_B_2024_TICKS|FIRST_M1_BAR");

   for(int i = 0; i < ArraySize(symbols); i++)
     {
      string sym = symbols[i];
      
      // In Market Watch auswaehlen
      SymbolSelect(sym, true); 
      
      double spread = SymbolInfoInteger(sym, SYMBOL_SPREAD);
      double tick_value = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
      double contract_size = SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE);
      
      // Window A Test (Jan 2022)
      MqlTick ticks_a[];
      int count_a = CopyTicksRange(sym, ticks_a, COPY_TICKS_ALL, D'2022.01.03 00:00'*1000, D'2022.01.10 00:00'*1000);
      bool has_a = (count_a > 0);
      
      // Window B Test (Jan 2024)
      MqlTick ticks_b[];
      int count_b = CopyTicksRange(sym, ticks_b, COPY_TICKS_ALL, D'2024.01.02 00:00'*1000, D'2024.01.09 00:00'*1000);
      bool has_b = (count_b > 0);
      
      // Earliest M1 bar as a proxy for history depth
      long first_m1 = SeriesInfoInteger(sym, PERIOD_M1, SERIES_FIRSTDATE);
      string first_m1_str = TimeToString((datetime)first_m1, TIME_DATE);
      if (first_m1 == 0) first_m1_str = "UNKNOWN";
      
      string line = sym + "|" + DoubleToString(spread, 0) + "|" + DoubleToString(tick_value, 5) + "|" + DoubleToString(contract_size, 2) + "|" + IntegerToString(has_a) + "|" + IntegerToString(has_b) + "|" + first_m1_str;
      FileWrite(h, line);
      Print(line);
     }
     
   FileClose(h);
   Print("=== Fertig. Datei: Common\\Files\\basket_data.txt ===");
   
   return(INIT_SUCCEEDED);
  }

void OnTick() { }
void OnDeinit(const int reason) { }
