//+------------------------------------------------------------------+
//| carry_basket_v1.mq5 - Carry-Trade (Zins-/Swap-Differenz)          |
//|                                                                  |
//| Idee: Halte die Seite eines FX-Paares, die den positiven Swap    |
//| (Zinsdifferenz) einnimmt - long wenn swap_long > swap_short,      |
//| sonst short. Gehalten mit weitem ATR-Schutzstopp (Carry-Unwinds   |
//| sind heftig). Richtung wird je Kerze der Arbeits-Zeitebene neu    |
//| geprueft; kippt das Vorzeichen, wird gedreht. Optionaler          |
//| Trend-Filter (Carry + Trend = klassische Kombi).                 |
//|                                                                  |
//| Test per-Symbol ueber einen Korb (jedes Symbol waehlt seine eigene|
//| Carry-Richtung), Ergebnisse gepoolt - KEIN Multi-Symbol, daher    |
//| keine Tester-Degradation wie beim Pair-Trading.                  |
//|                                                                  |
//| WICHTIG (Tester-Grenze): SYMBOL_SWAP_LONG/SHORT liefern im Tester |
//| die AKTUELLEN Swap-Werte (nicht historisch) -> die Carry-Richtung |
//| ist ueber den Backtest praktisch fix. Ehrlich einordnen.         |
//|                                                                  |
//| Nur Demo/Paper. Kein Live durch Claude.                          |
//+------------------------------------------------------------------+
#property copyright "Phase 3 / Teil 4 - Carry-Basket (Forschung)"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben ------------------------------------------------------
input group "--- Arbeits-Zeitebene / Carry ---"
input ENUM_TIMEFRAMES InpCarryTF        = PERIOD_D1; // Zeitebene der Richtungspruefung
input double          InpMinCarryPoints  = 0.0;      // Mindest |swap_long-swap_short| zum Handeln

input group "--- Trend-Filter (optional) ---"
input bool            InpUseTrendFilter  = false;    // Carry nur in Trendrichtung halten
input ENUM_TIMEFRAMES InpTrendTF         = PERIOD_W1;// Trend-Zeitebene
input int             InpTrendEMAPeriod  = 20;       // EMA-Periode fuer Trend

input group "--- Risiko / Stop ---"
input int             InpATRPeriod       = 14;       // ATR-Perioden (auf CarryTF)
input double          InpStopATRMult     = 3.0;      // Schutzstopp = x ATR (weit!)
input double          InpRiskPerTradePct = 1.0;      // Risiko pro Position (% vom Kapital)

input group "--- System ---"
input ulong           InpMagic           = 880030;   // Magic Number
input int             InpSlippage        = 5;        // Max. Slippage (Punkte)

//--- Globals -------------------------------------------------------
int      h_atr    = INVALID_HANDLE;
int      h_trend  = INVALID_HANDLE;
datetime m_lastBar = 0;
int      m_dir     = 0;      // aktuelle Positionsrichtung (+1/-1/0)
int      m_flips   = 0;      // Diagnose: Richtungswechsel
double   m_carryNow = 0.0;   // zuletzt gemessene Carry-Differenz

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);

   h_atr = iATR(_Symbol, InpCarryTF, InpATRPeriod);
   if(h_atr == INVALID_HANDLE) { Print("Fehler: ATR-Handle."); return(INIT_FAILED); }
   if(InpUseTrendFilter)
     {
      h_trend = iMA(_Symbol, InpTrendTF, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(h_trend == INVALID_HANDLE) { Print("Fehler: Trend-EMA-Handle."); return(INIT_FAILED); }
     }

   double sl = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
   double ss = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);
   Print("Carry-EA v1.0 ", _Symbol, ": swap_long=", DoubleToString(sl,2),
         " swap_short=", DoubleToString(ss,2), " -> Carry-Diff=",
         DoubleToString(sl-ss,2), " (", (sl>ss?"LONG":"SHORT"), "-Bias). ",
         "Hinweis: Swaps im Tester statisch = Richtung praktisch fix.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_atr   != INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_trend != INVALID_HANDLE) IndicatorRelease(h_trend);
   Print("Carry-EA Bilanz ", _Symbol, ": ", m_flips, " Richtungswechsel.");
  }

//+------------------------------------------------------------------+
//| Lot so, dass ein Stop-Treffer riskMoney kostet                   |
//+------------------------------------------------------------------+
double LotForStop(bool isLong, double entry, double stopDist, double riskMoney)
  {
   double exitP = isLong ? (entry - stopDist) : (entry + stopDist);
   ENUM_ORDER_TYPE ot = isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double lossPerLot = 0.0;
   if(!OrderCalcProfit(ot, _Symbol, 1.0, entry, exitP, lossPerLot)) return(0.0);
   lossPerLot = MathAbs(lossPerLot);
   if(lossPerLot <= 0.0) return(0.0);
   double lots = riskMoney / lossPerLot;
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step > 0) lots = MathFloor(lots/step)*step;
   if(lots < mn) lots = mn;
   if(lots > mx) lots = mx;
   return(lots);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   datetime bt = iTime(_Symbol, InpCarryTF, 0);
   if(bt == m_lastBar) return;
   m_lastBar = bt;

   double atr[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0) return;

   // 1. gewuenschte Carry-Richtung
   double sl = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
   double ss = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);
   double carry = sl - ss;
   m_carryNow = carry;
   int want = 0;
   if(carry >  InpMinCarryPoints) want = +1;
   else if(carry < -InpMinCarryPoints) want = -1;

   // 2. Trend-Filter (optional)
   if(InpUseTrendFilter && want != 0)
     {
      double ema[1];
      if(CopyBuffer(h_trend, 0, 1, 1, ema) < 1) return;
      double c = iClose(_Symbol, InpTrendTF, 1);
      if(c <= 0.0) return;
      bool up = (c > ema[0]);
      if((want == +1 && !up) || (want == -1 && up)) want = 0;
     }

   // 3. bestehende Position pruefen
   bool hasPos = PositionSelect(_Symbol);
   if(hasPos && PositionGetInteger(POSITION_MAGIC) != (long)InpMagic) hasPos = false;
   int curDir = 0;
   if(hasPos)
      curDir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? +1 : -1;

   // 4. Richtung stimmt -> halten (Stop bleibt)
   if(hasPos && curDir == want) { m_dir = curDir; return; }

   // 5. Richtung kippt oder Carry weg -> schliessen
   if(hasPos && curDir != want)
     {
      trade.PositionClose(_Symbol);
      m_flips++;
      m_dir = 0;
      // im selben Durchlauf nicht sofort neu eroeffnen (1 Bar Pause)
      return;
     }

   // 6. keine Position + gewuenschte Richtung -> eroeffnen mit ATR-Stop
   if(!hasPos && want != 0)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      bool isLong = (want == +1);
      double entry = isLong ? ask : bid;
      double stopDist = InpStopATRMult * atr[0];
      double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPerTradePct/100.0);
      double lots = LotForStop(isLong, entry, stopDist, riskMoney);
      if(lots <= 0.0) { Print("Carry ", _Symbol, ": Lot 0."); return; }
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double slPrice = isLong ? (entry - stopDist) : (entry + stopDist);
      slPrice = NormalizeDouble(slPrice, digits);
      bool ok = isLong ? trade.Buy(lots, _Symbol, ask, slPrice, 0, "Carry")
                       : trade.Sell(lots, _Symbol, bid, slPrice, 0, "Carry");
      if(ok) m_dir = want;
     }
  }

//+------------------------------------------------------------------+
//| OnTester: Basis-Kennzahlen (pool-kompatibel) + Carry-Diagnose    |
//+------------------------------------------------------------------+
double OnTester()
  {
   double profit      = TesterStatistics(STAT_PROFIT);
   double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss   = TesterStatistics(STAT_GROSS_LOSS);
   double sharpe      = TesterStatistics(STAT_SHARPE_RATIO);
   double balDDpct    = TesterStatistics(STAT_BALANCEDD_PERCENT);
   double trades      = TesterStatistics(STAT_TRADES);
   double winTrades   = TesterStatistics(STAT_PROFIT_TRADES);
   double lossTrades  = TesterStatistics(STAT_LOSS_TRADES);
   double conLossCnt  = TesterStatistics(STAT_CONLOSSMAX_TRADES);

   double winRate = (trades>0)     ? (winTrades/trades*100.0) : 0.0;
   double avgWin  = (winTrades>0)  ? (grossProfit/winTrades)  : 0.0;
   double avgLoss = (lossTrades>0) ? (grossLoss/lossTrades)   : 0.0;
   double absLoss = MathAbs(grossLoss);
   string pfStr = (absLoss>0.0)? DoubleToString(grossProfit/absLoss,2)
                               : (grossProfit>0.0? "inf":"0.00");

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "symbol="         + _Symbol);
      FileWrite(h, "net_profit="     + DoubleToString(profit,2));
      FileWrite(h, "profit_factor="  + pfStr);
      FileWrite(h, "sharpe="         + DoubleToString(sharpe,2));
      FileWrite(h, "balance_dd_pct=" + DoubleToString(balDDpct,2));
      FileWrite(h, "trades="         + DoubleToString(trades,0));
      FileWrite(h, "win_trades="     + DoubleToString(winTrades,0));
      FileWrite(h, "loss_trades="    + DoubleToString(lossTrades,0));
      FileWrite(h, "win_rate_pct="   + DoubleToString(winRate,2));
      FileWrite(h, "avg_win="        + DoubleToString(avgWin,2));
      FileWrite(h, "avg_loss="       + DoubleToString(avgLoss,2));
      FileWrite(h, "gross_profit="   + DoubleToString(grossProfit,2));
      FileWrite(h, "gross_loss="     + DoubleToString(grossLoss,2));
      FileWrite(h, "max_conloss_count=" + DoubleToString(conLossCnt,0));
      FileWrite(h, "carry_diff="     + DoubleToString(m_carryNow,2));
      FileWrite(h, "dir_flips="      + IntegerToString(m_flips));
      FileClose(h);
     }
   return(profit);
  }
//+------------------------------------------------------------------+
