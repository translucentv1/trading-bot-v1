//+------------------------------------------------------------------+
//| pair_trading_v1.mq5 - Cointegration Pair-Trading (Phase 2)        |
//|                                                                  |
//| Handelt den Spread zweier cointegrierter Symbole (Phase-1-Gate:  |
//| EURUSD~GBPUSD, AUDUSD~USDCAD). Mean-Reversion auf den z-Score     |
//| des Log-Spreads. Alles Look-Ahead-frei (Kerzen ab Index 1).      |
//|                                                                  |
//| WICHTIG (Blindstelle 1.2.1 aus dem Review): Der MT5-Tester laedt |
//| volle Tick-Daten nur fuer das HAUPT-Symbol; das Sekundaer-Symbol |
//| ist im Tester grob aufgeloest -> Pair-Ergebnisse sind eine OBERE |
//| SCHRANKE, keine realistische Simulation. Modus "1 Minute OHLC"   |
//| bewusst waehlen, Ergebnis so lesen.                              |
//|                                                                  |
//| Nur Demo/Paper. Kein Martingale/Nachkaufen (max 1 Spread offen). |
//+------------------------------------------------------------------+
#property copyright "Phase 2 - Pair-Trading (Forschung)"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Paar & Zeitebene ------------------------------------
input group "--- Paar / Zeitebene ---"
input string          InpSymbolA      = "EURUSD"; // Symbol A (= Chart-Symbol im Tester!)
input string          InpSymbolB      = "GBPUSD"; // Symbol B (sekundaer)
input ENUM_TIMEFRAMES InpTimeframe    = PERIOD_H1;// Arbeits-Zeitebene
input int             InpHedgeLookback= 500;      // Kerzen fuer Hedge-Ratio (Index ab 1)
input int             InpSpreadLookback=100;      // Kerzen fuer Spread-Mittel/Std

//--- Eingaben: Ein-/Ausstieg (a priori, NICHT optimieren) ----------
input group "--- z-Score Ein/Ausstieg ---"
input double          InpZEntry       = 2.0;      // Einstieg bei |z| >= diesem Wert
input double          InpZStop        = 3.5;      // Hard-Stop bei |z| >= diesem Wert
input int             InpMaxHoldBars  = 200;      // Time-Stop (Bars, ~8 Tage H1)

//--- Eingaben: Risiko / Kosten -------------------------------------
input group "--- Risiko / Kosten ---"
input double          InpRiskPerTradePct = 1.0;   // Gesamt-Risiko/Spread (je Bein die Haelfte)
input double          InpCommissionPerLot= 3.5;   // Kommission je Lot & Seite (Kontowaehrung)
input double          InpCostSafetyMult  = 2.0;   // Einstieg nur wenn Erwartung > Mult x Kosten

//--- Eingaben: System ----------------------------------------------
input group "--- System ---"
input ulong           InpMagic        = 880020;   // Magic Number
input int             InpSlippage     = 5;        // Max. Slippage (Punkte)

//--- globale Zustaende ---------------------------------------------
datetime m_lastBar    = 0;
bool     m_hasPos     = false;
bool     m_isLongSpr  = false;   // true = Long A / Short B
ulong    m_ticketA    = 0;
ulong    m_ticketB    = 0;
int      m_barsHeld   = 0;
double   m_lastBeta   = 0.0;

// Kennzahlen-Sammler fuer OnTester
int      m_nEntries   = 0;
double   m_sumZ       = 0.0;
double   m_sumHold    = 0.0;
double   m_sumCost    = 0.0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpHedgeLookback < 50 || InpSpreadLookback < 20 || InpSpreadLookback > InpHedgeLookback)
     {
      Print("Fehler: Lookbacks unplausibel (Hedge>=50, 20<=Spread<=Hedge).");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!SymbolSelect(InpSymbolA, true) || !SymbolSelect(InpSymbolB, true))
     {
      Print("Fehler: Symbol A oder B nicht verfuegbar (", InpSymbolA, "/", InpSymbolB, ").");
      return(INIT_FAILED);
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);

   Print("WARNING: MT5 Strategy Tester liefert nur fuer das Haupt-Symbol volle "
         "Tick-Daten. Sekundaer-Symbol hat degraded ticks. Pair-Trading-Ergebnisse "
         "sind eine OBERE SCHRANKE, keine realistische Simulation.");
   Print("Pair-Trading v1 gestartet: ", InpSymbolA, " ~ ", InpSymbolB,
         " | TF ", EnumToString(InpTimeframe), " | ZEntry ", InpZEntry, " ZStop ", InpZStop);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason) { }

//+------------------------------------------------------------------+
//| Holt Log-Schlusskurse ab Index 1 (Look-Ahead-frei), Serie:       |
//| arr[0] = zuletzt geschlossene Kerze.                             |
//+------------------------------------------------------------------+
bool GetLogCloses(string sym, int count, double &arr[])
  {
   double c[];
   ArraySetAsSeries(c, true);
   if(CopyClose(sym, InpTimeframe, 1, count, c) < count) return(false);
   ArrayResize(arr, count);
   for(int i = 0; i < count; i++)
     {
      if(c[i] <= 0.0) return(false);
      arr[i] = MathLog(c[i]);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Hedge-Ratio beta = Cov(A,B)/Var(B) ueber die Log-Kurse           |
//+------------------------------------------------------------------+
double HedgeRatio(const double &la[], const double &lb[], int n)
  {
   double mA=0, mB=0;
   for(int i=0;i<n;i++){ mA+=la[i]; mB+=lb[i]; } mA/=n; mB/=n;
   double cov=0, varB=0;
   for(int i=0;i<n;i++){ double da=la[i]-mA, db=lb[i]-mB; cov+=da*db; varB+=db*db; }
   return((varB>0)? cov/varB : 0.0);
  }

//+------------------------------------------------------------------+
//| Aktueller z-Score des Spreads + Std zurueck (via Referenz)       |
//+------------------------------------------------------------------+
bool ComputeZ(double &zOut, double &stdOut, double &betaOut, double &spreadNow)
  {
   int n = InpHedgeLookback;
   double la[], lb[];
   if(!GetLogCloses(InpSymbolA, n, la)) return(false);
   if(!GetLogCloses(InpSymbolB, n, lb)) return(false);

   double beta = HedgeRatio(la, lb, n);
   betaOut = beta;

   // Spread-Statistik ueber die letzten InpSpreadLookback Kerzen
   int m = InpSpreadLookback;
   double sMean=0;
   double spr[]; ArrayResize(spr, m);
   for(int i=0;i<m;i++){ spr[i] = la[i] - beta*lb[i]; sMean += spr[i]; }
   sMean /= m;
   double var=0;
   for(int i=0;i<m;i++){ double d=spr[i]-sMean; var+=d*d; }
   double sd = (m>1)? MathSqrt(var/(m-1)) : 0.0;
   if(sd <= 0.0) return(false);

   spreadNow = spr[0];               // zuletzt geschlossene Kerze
   stdOut    = sd;
   zOut      = (spr[0]-sMean)/sd;
   return(true);
  }

//+------------------------------------------------------------------+
//| Round-Turn-Kosten (Kontowaehrung) fuer beide Beine bei gg. Lots  |
//+------------------------------------------------------------------+
double RoundTurnCost(double lotA, double lotB)
  {
   double cost = 0.0;
   string legs[2]; legs[0]=InpSymbolA; legs[1]=InpSymbolB;
   double lots[2]; lots[0]=lotA; lots[1]=lotB;
   for(int k=0;k<2;k++)
     {
      double ask=SymbolInfoDouble(legs[k],SYMBOL_ASK);
      double bid=SymbolInfoDouble(legs[k],SYMBOL_BID);
      double ts =SymbolInfoDouble(legs[k],SYMBOL_TRADE_TICK_SIZE);
      double tv =SymbolInfoDouble(legs[k],SYMBOL_TRADE_TICK_VALUE);
      if(ts>0 && tv>0)
         cost += ((ask-bid)/ts)*tv*lots[k];      // Spread-Kosten
      cost += InpCommissionPerLot*lots[k]*2.0;    // Kommission Round-Turn
     }
   return(cost);
  }

//+------------------------------------------------------------------+
//| Lot fuer ein Bein: Verlust bei SL-Distanz = riskMoney            |
//+------------------------------------------------------------------+
double LotForLeg(string sym, bool isLong, double price, double slDist, double riskMoney)
  {
   double exitP = isLong ? (price - slDist) : (price + slDist);
   ENUM_ORDER_TYPE ot = isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double lossPerLot=0;
   if(OrderCalcProfit(ot, sym, 1.0, price, exitP, lossPerLot))
      lossPerLot = MathAbs(lossPerLot);
   if(lossPerLot <= 0.0) return(0.0);
   double lots = riskMoney/lossPerLot;
   double step = SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
   if(step>0) lots = MathFloor(lots/step)*step;
   if(lots<mn) lots=mn;
   if(lots>mx) lots=mx;
   return(lots);
  }

//+------------------------------------------------------------------+
//| Beide Beine schliessen                                           |
//+------------------------------------------------------------------+
void CloseSpread()
  {
   if(m_ticketA>0 && PositionSelectByTicket(m_ticketA)) trade.PositionClose(m_ticketA);
   if(m_ticketB>0 && PositionSelectByTicket(m_ticketB)) trade.PositionClose(m_ticketB);
   m_hasPos=false; m_ticketA=0; m_ticketB=0; m_barsHeld=0;
  }

//+------------------------------------------------------------------+
//| Spread eroeffnen. longSpread = Long A / Short B                  |
//+------------------------------------------------------------------+
void OpenSpread(bool longSpread, double z, double sd, double beta)
  {
   double askA=SymbolInfoDouble(InpSymbolA,SYMBOL_ASK), bidA=SymbolInfoDouble(InpSymbolA,SYMBOL_BID);
   double askB=SymbolInfoDouble(InpSymbolB,SYMBOL_ASK), bidB=SymbolInfoDouble(InpSymbolB,SYMBOL_BID);
   double entryA = longSpread ? askA : bidA;
   double entryB = longSpread ? bidB : askB;   // Bein B gegenlaeufig

   // Adverse Spread-Bewegung bis zum Hard-Stop (in Log-Einheiten)
   double dS = (InpZStop - InpZEntry) * sd;
   if(dS <= 0.0) return;
   // In Preis-Distanz je Bein umsetzen (konservativ: volle Bewegung je Bein)
   double slA = entryA * dS;
   double slB = entryB * (beta!=0.0 ? dS/MathAbs(beta) : dS);

   double riskLeg = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPerTradePct/100.0) / 2.0;
   double lotA = LotForLeg(InpSymbolA, longSpread,  entryA, slA, riskLeg);
   double lotB = LotForLeg(InpSymbolB, !longSpread, entryB, slB, riskLeg);
   if(lotA<=0 || lotB<=0){ Print("Pair: Lot 0 - kein Einstieg."); return; }

   // --- Kosten-Check (Blindstelle 1.2.5) ---
   double cost = RoundTurnCost(lotA, lotB);
   // Erwarteter Gewinn: Rueckkehr des Spreads von |z| auf 0 -> |z|*sd (Log) auf Bein A
   double expProfit = 0.0, tmp=0.0;
   double aRet = MathAbs(z)*sd;                 // Log-Rueckkehr
   double aExit = entryA*(1.0 + (longSpread? aRet : -aRet));
   if(OrderCalcProfit(longSpread?ORDER_TYPE_BUY:ORDER_TYPE_SELL, InpSymbolA, lotA, entryA, aExit, tmp))
      expProfit = MathAbs(tmp);
   if(expProfit < InpCostSafetyMult*cost)
     {
      // zu teuer -> Signal verwerfen
      return;
     }

   // --- Orders ---
   double slPriceA = longSpread ? (entryA-slA) : (entryA+slA);
   double slPriceB = longSpread ? (entryB+slB) : (entryB-slB); // B gegenlaeufig
   slPriceA = NormalizeDouble(slPriceA, (int)SymbolInfoInteger(InpSymbolA,SYMBOL_DIGITS));
   slPriceB = NormalizeDouble(slPriceB, (int)SymbolInfoInteger(InpSymbolB,SYMBOL_DIGITS));

   bool okA = longSpread ? trade.Buy(lotA, InpSymbolA, askA, slPriceA, 0, "PairA")
                         : trade.Sell(lotA, InpSymbolA, bidA, slPriceA, 0, "PairA");
   ulong tA = trade.ResultOrder();
   bool okB = longSpread ? trade.Sell(lotB, InpSymbolB, bidB, slPriceB, 0, "PairB")
                         : trade.Buy(lotB, InpSymbolB, askB, slPriceB, 0, "PairB");
   ulong tB = trade.ResultOrder();

   if(!okA || !okB)
     {
      Print("Pair-Einstieg fehlgeschlagen (okA=",okA," okB=",okB,") - schliesse evtl. Teil.");
      if(okA && tA>0 && PositionSelectByTicket(tA)) trade.PositionClose(tA);
      if(okB && tB>0 && PositionSelectByTicket(tB)) trade.PositionClose(tB);
      return;
     }
   m_hasPos=true; m_isLongSpr=longSpread; m_ticketA=tA; m_ticketB=tB; m_barsHeld=0;
   m_nEntries++; m_sumZ += MathAbs(z); m_sumCost += cost;
   Print((longSpread?"LONG":"SHORT")," SPREAD ",InpSymbolA,"~",InpSymbolB,
         " | z=",DoubleToString(z,2)," beta=",DoubleToString(beta,4),
         " | LotA=",DoubleToString(lotA,2)," LotB=",DoubleToString(lotB,2),
         " | Kosten~",DoubleToString(cost,2));
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   datetime bt = iTime(_Symbol, InpTimeframe, 0);
   if(bt == m_lastBar) return;      // nur einmal je neuer Kerze
   m_lastBar = bt;

   double z, sd, beta, spr;
   if(!ComputeZ(z, sd, beta, spr)) return;
   m_lastBeta = beta;

   // --- Position vorhanden? Beine pruefen + Ausstiege ---
   if(m_hasPos)
     {
      m_barsHeld++;
      bool aOpen = (m_ticketA>0 && PositionSelectByTicket(m_ticketA));
      bool bOpen = (m_ticketB>0 && PositionSelectByTicket(m_ticketB));
      if(!aOpen || !bOpen)          // ein Bein weg (SL getroffen) -> anderes schliessen
        { CloseSpread(); return; }

      bool tpHit   = m_isLongSpr ? (z >= 0.0) : (z <= 0.0);   // Rueckkehr zum Mittel
      bool stopHit = (MathAbs(z) >= InpZStop);
      bool timeHit = (m_barsHeld >= InpMaxHoldBars);
      if(tpHit || stopHit || timeHit)
        {
         m_sumHold += m_barsHeld;
         Print("Spread-Ausstieg: ",(tpHit?"TP(z->0)":stopHit?"HardStop":"TimeStop"),
               " | z=",DoubleToString(z,2));
         CloseSpread();
        }
      return;
     }

   // --- kein offener Spread: Einstieg pruefen ---
   if(z <= -InpZEntry)      OpenSpread(true,  z, sd, beta);   // Long Spread
   else if(z >= InpZEntry)  OpenSpread(false, z, sd, beta);   // Short Spread
  }

//+------------------------------------------------------------------+
//| OnTester: Basis-Spalten wie ema_mtf_v3 (fuer pool_backtests.py)  |
//| + neue Pair-Spalten. Semikolon-getrennt in Common\Files.        |
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

   double avgZ    = (m_nEntries>0)? m_sumZ/m_nEntries : 0.0;
   double avgHold = (m_nEntries>0)? m_sumHold/m_nEntries : 0.0;
   double avgCost = (m_nEntries>0)? m_sumCost/m_nEntries : 0.0;

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "symbol="         + InpSymbolA);
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
      // --- neue Pair-Spalten ---
      FileWrite(h, "pair_id="        + InpSymbolA + "_" + InpSymbolB);
      FileWrite(h, "hedge_ratio="    + DoubleToString(m_lastBeta,6));
      FileWrite(h, "avg_z_at_entry=" + DoubleToString(avgZ,2));
      FileWrite(h, "avg_hold_bars="  + DoubleToString(avgHold,1));
      FileWrite(h, "round_turn_cost_eur=" + DoubleToString(avgCost,2));
      FileWrite(h, "test_mode=tester_multi_symbol_limited");
      FileClose(h);
     }
   return(profit);
  }
//+------------------------------------------------------------------+
