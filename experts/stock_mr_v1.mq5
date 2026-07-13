//+------------------------------------------------------------------+
//| stock_mr_v1.mq5 - Aktien Mean-Reversion (RSI Oversold Bounce)   |
//|                                                                  |
//| Idee: "Buy the Dip" in starken Aktien-Aufwaertstrends.           |
//| - Nur LONG (Aktien haben Equity-Risk-Premium)                    |
//| - Trend-Filter: Kurs ueber SMA(200) auf D1                       |
//| - Einstieg: RSI(2) faellt unter Schwelle (extrem ueberverkauft)  |
//| - Ausstieg: RSI(2) steigt ueber obere Schwelle ODER Zeitstopp   |
//| - Schutzstopp: ATR-basiert (weiter, weil Mean-Rev.)              |
//|                                                                  |
//| Basiert auf dokumentierter Connors-RSI-Strategie fuer US-Aktien. |
//| Position per Symbol einzeln (kein Multi-Symbol im Tester),        |
//| Ergebnisse gepoolt ueber Korb wie bei FX-Tests.                  |
//|                                                                  |
//| Nur Demo/Paper. Kein Live durch Claude.                          |
//+------------------------------------------------------------------+
#property copyright "Phase 4 - Stock Mean-Reversion (Forschung)"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben ------------------------------------------------------
input group "--- Signal / RSI ---"
input int             InpRSIPeriod       = 2;       // RSI-Periode (kurz = aggressiver)
input double          InpRSIEntry        = 10.0;    // Kauf wenn RSI < dieser Wert
input double          InpRSIExit         = 80.0;    // Verkauf wenn RSI > dieser Wert
input int             InpMaxHoldBars     = 5;       // Zeitstopp: max. Halteperioden (0=aus)

input group "--- Trend-Filter ---"
input int             InpSMAPeriod       = 200;     // SMA-Periode (Trend-Filter)
input bool            InpUseTrendFilter  = true;    // Kurs muss > SMA sein

input group "--- Risiko / Stop ---"
input int             InpATRPeriod       = 14;      // ATR-Perioden fuer Stop
input double          InpStopATRMult     = 3.0;     // Stop = x ATR unter Einstieg
input double          InpRiskPerTradePct = 1.0;     // Risiko pro Trade (% Kapital)

input group "--- System ---"
input ulong           InpMagic           = 880040;  // Magic Number
input int             InpSlippage        = 10;      // Max. Slippage (Punkte, Aktien brauchen mehr)

//--- Globale Variablen ---------------------------------------------
int      h_rsi   = INVALID_HANDLE;
int      h_sma   = INVALID_HANDLE;
int      h_atr   = INVALID_HANDLE;
datetime m_lastBar = 0;
int      m_entryBar = 0;          // Bar-Index beim Einstieg
int      m_barsInTrade = 0;       // Zaehler Halteperioden
int      m_totalTrades = 0;
int      m_trendBlocked = 0;      // Diagnose: wie oft Trend-Filter blockiert

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);

   h_rsi = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   h_sma = iMA(_Symbol, PERIOD_D1, InpSMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   h_atr = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);

   if(h_rsi == INVALID_HANDLE || h_sma == INVALID_HANDLE || h_atr == INVALID_HANDLE)
     {
      Print("Fehler: Indikator-Handle konnte nicht erstellt werden.");
      return(INIT_FAILED);
     }

   Print("Stock-MR v1.0 ", _Symbol, " | RSI(", InpRSIPeriod, ") Entry<", InpRSIEntry,
         " Exit>", InpRSIExit, " | SMA(", InpSMAPeriod, ") Filter=", InpUseTrendFilter,
         " | Stop=", InpStopATRMult, "xATR | MaxHold=", InpMaxHoldBars);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_rsi != INVALID_HANDLE) IndicatorRelease(h_rsi);
   if(h_sma != INVALID_HANDLE) IndicatorRelease(h_sma);
   if(h_atr != INVALID_HANDLE) IndicatorRelease(h_atr);
   Print("Stock-MR Bilanz ", _Symbol, ": ", m_totalTrades, " Trades, ",
         m_trendBlocked, " mal durch Trend-Filter blockiert.");
  }

//+------------------------------------------------------------------+
double LotForRisk(double entry, double stopDist, double riskMoney)
  {
   double exitP = entry - stopDist;
   double lossPerLot = 0.0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0, entry, exitP, lossPerLot))
      return(0.0);
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
   datetime bt = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bt == m_lastBar) return;
   m_lastBar = bt;

   // Indikator-Werte (Index 1 = letzte geschlossene Kerze)
   double rsi[1], sma[1], atr[1];
   if(CopyBuffer(h_rsi, 0, 1, 1, rsi) < 1) return;
   if(CopyBuffer(h_sma, 0, 1, 1, sma) < 1) return;
   if(CopyBuffer(h_atr, 0, 1, 1, atr) < 1) return;
   if(atr[0] <= 0.0) return;

   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   // Bestehende Position pruefen
   bool hasPos = false;
   if(PositionSelect(_Symbol))
     {
      if(PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
         hasPos = true;
     }

   // === Position-Management ===
   if(hasPos)
     {
      m_barsInTrade++;

      // Exit-Bedingung 1: RSI ueber oberer Schwelle
      bool rsiExit = (rsi[0] > InpRSIExit);

      // Exit-Bedingung 2: Zeitstopp
      bool timeExit = (InpMaxHoldBars > 0 && m_barsInTrade >= InpMaxHoldBars);

      if(rsiExit || timeExit)
        {
         trade.PositionClose(_Symbol);
        }
      return;
     }

   // === Entry-Logik (nur wenn keine Position) ===

   // Trend-Filter: Kurs muss ueber SMA(200) sein
   if(InpUseTrendFilter && closePrice <= sma[0])
     {
      m_trendBlocked++;
      return;
     }

   // RSI unter Einstiegs-Schwelle = ueberverkauft = kaufen
   if(rsi[0] < InpRSIEntry)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double stopDist = InpStopATRMult * atr[0];
      double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPerTradePct / 100.0);
      double lots = LotForRisk(ask, stopDist, riskMoney);
      if(lots <= 0.0) { Print("Stock-MR ", _Symbol, ": Lot=0, skip."); return; }

      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double slPrice = NormalizeDouble(ask - stopDist, digits);

      if(trade.Buy(lots, _Symbol, ask, slPrice, 0, "StockMR"))
        {
         m_barsInTrade = 0;
         m_totalTrades++;
        }
     }
  }

//+------------------------------------------------------------------+
//| OnTester: Kennzahlen (pool-kompatibel)                           |
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
      FileWrite(h, "rsi_period="     + IntegerToString(InpRSIPeriod));
      FileWrite(h, "rsi_entry="      + DoubleToString(InpRSIEntry,1));
      FileWrite(h, "rsi_exit="       + DoubleToString(InpRSIExit,1));
      FileWrite(h, "max_hold="       + IntegerToString(InpMaxHoldBars));
      FileWrite(h, "trend_blocked="  + IntegerToString(m_trendBlocked));
      FileClose(h);
     }
   return(profit);
  }
//+------------------------------------------------------------------+
