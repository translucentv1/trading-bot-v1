//+------------------------------------------------------------------+
//| export_daily.mq5 - Exportiert Tages-OHLC + Indikatoren           |
//|                                                                  |
//| Zweck: Kontroll-Experiment (Weg A) in Python. Dumpt fuer das      |
//| Chart-Symbol die D1-Serie (OHLC) plus RSI(2), SMA(200), ATR(14)  |
//| aus MT5 selbst, damit der Python-Nachbau EXAKT dieselben          |
//| Indikatorwerte nutzt wie der Tester. Kein Trading.               |
//|                                                                  |
//| Ausgabe: Common\Files\export_<SYMBOL>.csv (Semikolon-getrennt).  |
//| Nur Demo/Forschung. Kein Live.                                   |
//+------------------------------------------------------------------+
#property copyright "Phase 4 - Datenexport (Forschung)"
#property version   "1.00"
#property strict

input int InpRSIPeriod = 2;     // RSI-Periode
input int InpSMAPeriod = 200;   // SMA-Periode (Trend-Filter)
input int InpATRPeriod = 14;    // ATR-Periode
input int InpBars      = 2500;  // Anzahl D1-Bars die exportiert werden

int h_rsi = INVALID_HANDLE;
int h_sma = INVALID_HANDLE;
int h_atr = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
  {
   h_rsi = iRSI(_Symbol, PERIOD_D1, InpRSIPeriod, PRICE_CLOSE);
   h_sma = iMA(_Symbol, PERIOD_D1, InpSMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   h_atr = iATR(_Symbol, PERIOD_D1, InpATRPeriod);
   if(h_rsi==INVALID_HANDLE || h_sma==INVALID_HANDLE || h_atr==INVALID_HANDLE)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_rsi!=INVALID_HANDLE) IndicatorRelease(h_rsi);
   if(h_sma!=INVALID_HANDLE) IndicatorRelease(h_sma);
   if(h_atr!=INVALID_HANDLE) IndicatorRelease(h_atr);
  }

//+------------------------------------------------------------------+
double OnTester()
  {
   ExportSeries();
   return(0.0);
  }

//+------------------------------------------------------------------+
void ExportSeries()
  {
   int n = InpBars;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int got = CopyRates(_Symbol, PERIOD_D1, 0, n, rates);
   if(got <= 0) { Print("CopyRates fehlgeschlagen ", _Symbol); return; }

   double rsi[], sma[], atr[];
   ArraySetAsSeries(rsi, true); ArraySetAsSeries(sma, true); ArraySetAsSeries(atr, true);
   if(CopyBuffer(h_rsi,0,0,got,rsi) < got) { Print("RSI copy < got"); }
   if(CopyBuffer(h_sma,0,0,got,sma) < got) { Print("SMA copy < got"); }
   if(CopyBuffer(h_atr,0,0,got,atr) < got) { Print("ATR copy < got"); }

   string fname = "export_" + _Symbol + ".csv";
   int fh = FileOpen(fname, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(fh == INVALID_HANDLE) { Print("FileOpen fehlgeschlagen ", fname); return; }

   FileWrite(fh, "date;open;high;low;close;rsi;sma;atr");
   // Chronologisch schreiben (aeltester zuerst): rueckwaerts durch Serie
   for(int i=got-1; i>=0; i--)
     {
      string line = TimeToString(rates[i].time, TIME_DATE) + ";" +
                    DoubleToString(rates[i].open,4)  + ";" +
                    DoubleToString(rates[i].high,4)  + ";" +
                    DoubleToString(rates[i].low,4)   + ";" +
                    DoubleToString(rates[i].close,4) + ";" +
                    DoubleToString(rsi[i],2) + ";" +
                    DoubleToString(sma[i],4) + ";" +
                    DoubleToString(atr[i],4);
      FileWrite(fh, line);
     }
   FileClose(fh);
   Print("Export ok: ", fname, " (", got, " Bars)");
  }
//+------------------------------------------------------------------+
