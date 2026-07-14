//+------------------------------------------------------------------+
//| export_universe.mq5 - Bulk-Export D1-Kurse vieler Aktien         |
//|                                                                  |
//| Fuer Phase 5 (markt-neutral Long/Short). Liest die Symbol-Liste  |
//| aus Common\Files\phase5_short_check.csv und exportiert je Symbol |
//| die D1-Serie (date;open;close;tickvol) nach                      |
//| Common\Files\univ_<SYMBOL>.csv. Batchbar via InpStart/InpCount.  |
//| Kein Trading. Nutzt OnTester (Daten am Testende geladen).        |
//+------------------------------------------------------------------+
#property copyright "Phase 5 - Universum-Export"
#property version   "1.00"
#property strict

input int    InpStart    = 0;                          // Startindex in der Symbol-Liste
input int    InpCount    = 1000;                       // Anzahl Symbole in dieser Charge
input int    InpBars     = 2500;                       // D1-Bars je Symbol
input string InpListFile = "phase5_short_check.csv";   // Quell-Liste (Common\Files)

string g_syms[];

int LoadSymbols()
  {
   int fh = FileOpen(InpListFile, FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(fh==INVALID_HANDLE) { Print("Universum-Liste nicht lesbar"); return(0); }
   int n=0;
   while(!FileIsEnding(fh))
     {
      string line=FileReadString(fh);
      if(StringLen(line)<2) continue;
      if(StringGetCharacter(line,0)=='#') continue;        // Summenzeile
      if(StringFind(line,"symbol;")==0) continue;          // Kopf
      string parts[];
      if(StringSplit(line,';',parts)<1) continue;
      string sym=parts[0];
      if(StringLen(sym)<1) continue;
      ArrayResize(g_syms,n+1); g_syms[n]=sym; n++;
     }
   FileClose(fh);
   return(n);
  }

double OnTester()
  {
   int n=LoadSymbols();
   if(n==0) return(0.0);
   int from=InpStart, to=MathMin(InpStart+InpCount, n);
   int okCount=0;
   for(int k=from;k<to;k++)
     {
      string sym=g_syms[k];
      MqlRates rates[]; ArraySetAsSeries(rates,true);
      int got=CopyRates(sym, PERIOD_D1, 0, InpBars, rates);
      if(got<=0) { Print("keine Daten: ",sym); continue; }
      long vol[]; ArraySetAsSeries(vol,true);
      int gv=CopyTickVolume(sym, PERIOD_D1, 0, got, vol);
      string fn="univ_"+sym+".csv";
      int h=FileOpen(fn, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
      if(h==INVALID_HANDLE) { Print("FileOpen fail ",fn); continue; }
      FileWrite(h,"date;open;close;tickvol");
      for(int i=got-1;i>=0;i--)
        {
         long tv = (gv==got && i<gv) ? vol[i] : 0;
         FileWrite(h, TimeToString(rates[i].time,TIME_DATE)+";"+
                   DoubleToString(rates[i].open,4)+";"+
                   DoubleToString(rates[i].close,4)+";"+
                   IntegerToString((int)tv));
        }
      FileClose(h);
      okCount++;
     }
   Print("Universum-Export Charge ",from,"..",to," fertig, ok=",okCount," von ",(to-from));
   return((double)okCount);
  }

int OnInit(){ return(INIT_SUCCEEDED); }
void OnTick(){}
void OnDeinit(const int reason){}
//+------------------------------------------------------------------+
