//+------------------------------------------------------------------+
//| EMA 9/21 + Multi-Timeframe-Bias - v3.0 (Long & Short)           |
//|                                                                  |
//| Idee (Market-Structure / Top-Down):                             |
//|  - HOEHERE Zeitebene (Standard H4) gibt die RICHTUNG (Bias):    |
//|    Schlusskurs ueber Bias-EMA = Aufwaerts, darunter = Abwaerts. |
//|  - AUSFUEHRUNGS-Zeitebene (Chart, z.B. M15/M30/H1) gibt das     |
//|    TIMING: EMA 9 kreuzt EMA 21.                                 |
//|  - LONG:  Golden Cross UND Bias aufwaerts UND RSI nicht         |
//|           ueberkauft.                                           |
//|  - SHORT: Death Cross  UND Bias abwaerts UND RSI nicht          |
//|           ueberverkauft.                                        |
//|  RISIKO (wie v2.0, jetzt fuer beide Richtungen gespiegelt):     |
//|   - Long:  Stop unter das letzte Swing-Tief  - ATR-Puffer.     |
//|   - Short: Stop ueber das letzte Swing-Hoch + ATR-Puffer.      |
//|   - Take-Profit = Risiko x InpRewardRatio (dynamisch).         |
//|   - ATR-Trailing-Stop, risikobasierte Lotgroesse.             |
//|   - Tagesverlust-Stopp.                                         |
//|                                                                  |
//| Nur fuer Demo-/Paper-Trading. Kompilieren (F7) und Strategy      |
//| Tester laufen im MetaEditor/MT5.                                |
//+------------------------------------------------------------------+
#property copyright "Phase 3 - Demo/Paper"
#property version   "3.00"
#property strict
#property description "EMA 9/21 + Multi-Timeframe-Bias, Long & Short,"
#property description "Struktur-Stop, dynamischer TP, ATR-Trailing, RSI-Filter."

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Signal-EMAs (Ausfuehrungs-Zeitebene = Chart) ---------
input group "--- Signal-EMAs (Chart-Zeitebene) ---"
input int             InpFastEMAPeriod  = 9;        // Perioden schnelle EMA
input int             InpSlowEMAPeriod  = 21;       // Perioden langsame EMA

//--- Eingaben: Trend-Bias (hoehere Zeitebene) -----------------------
input group "--- Trend-Bias (hoehere Zeitebene) ---"
input ENUM_TIMEFRAMES InpBiasTF         = PERIOD_H4;// Hoehere Zeitebene fuer Richtung
input int             InpBiasEMAPeriod  = 50;       // EMA auf der Bias-Zeitebene

//--- Eingaben: Handelsrichtung --------------------------------------
input group "--- Handelsrichtung ---"
input bool            InpAllowLong      = true;     // Long-Trades erlauben
input bool            InpAllowShort     = false;    // Short-Trades erlauben (auf EURUSD long-only besser, s. Backtests)

//--- Eingaben: RSI-Filter -------------------------------------------
input group "--- RSI-Filter ---"
input bool            InpUseRSIFilter   = true;     // RSI-Filter aktivieren
input int             InpRSIPeriod      = 14;       // Perioden RSI
input double          InpRSIUpper       = 70.0;     // kein Long wenn RSI darueber
input double          InpRSILower       = 30.0;     // kein Short wenn RSI darunter

//--- Eingaben: Marktstruktur (Stop-Loss) ----------------------------
input group "--- Marktstruktur / Stop-Loss ---"
input int             InpSwingLookback  = 12;       // Kerzen zurueck fuer Swing-Punkt
input int             InpATRPeriod      = 14;       // Perioden ATR
input double          InpATRBufferMult  = 0.5;      // ATR-Puffer hinter dem Swing-Punkt

//--- Eingaben: Take-Profit / Trailing -------------------------------
input group "--- Take-Profit / Trailing ---"
input double          InpRewardRatio    = 1.8;      // TP = Risiko x diesem Faktor
input bool            InpUseTrailing    = true;     // ATR-Trailing-Stop aktivieren
input double          InpTrailATRMult   = 2.5;      // Trailing-Abstand in ATR

//--- Eingaben: Risiko / Position ------------------------------------
input group "--- Risiko / Position ---"
input bool            InpUseRiskLots    = true;     // Lot aus Risiko% berechnen
input double          InpRiskPerTradePct= 1.0;      // Risiko pro Trade (% vom Kapital)
input double          InpLotSize        = 0.10;     // Feste Lotgroesse (falls Risk aus)
input double          InpDailyLossLimit = 5.0;      // Tagesverlust-Limit (% vom Kapital)

//--- Eingaben: System ----------------------------------------------
input group "--- System ---"
input ulong           InpMagicNumber    = 990030;   // Magic Number
input int             InpSlippage       = 3;        // Max. Slippage (Punkte)

//--- globale Variablen / Indikator-Handles --------------------------
int      h_fastEMA  = INVALID_HANDLE;
int      h_slowEMA  = INVALID_HANDLE;
int      h_atr      = INVALID_HANDLE;
int      h_rsi      = INVALID_HANDLE;
int      h_biasEMA  = INVALID_HANDLE;

datetime m_last_bar_time;
bool     m_loss_limit_active;
int      m_last_day;
double   m_day_start_balance;

//+------------------------------------------------------------------+
//| Initialisierung                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastEMAPeriod >= InpSlowEMAPeriod)
     {
      Print("Fehler: schnelle EMA muss kleiner als langsame EMA sein.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!InpAllowLong && !InpAllowShort)
     {
      Print("Fehler: mindestens eine Handelsrichtung muss erlaubt sein.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   h_fastEMA = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   h_slowEMA = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   h_atr     = iATR(_Symbol, _Period, InpATRPeriod);
   h_biasEMA = iMA(_Symbol, InpBiasTF, InpBiasEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_fastEMA == INVALID_HANDLE || h_slowEMA == INVALID_HANDLE ||
      h_atr == INVALID_HANDLE || h_biasEMA == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen der Indikator-Handles!");
      return(INIT_FAILED);
     }

   if(InpUseRSIFilter)
     {
      h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
      if(h_rsi == INVALID_HANDLE)
        {
         Print("Fehler beim Erstellen des RSI Handles!");
         return(INIT_FAILED);
        }
     }

   m_last_bar_time     = 0;
   m_loss_limit_active = false;
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("EA v3.0 gestartet: EMA ", InpFastEMAPeriod, "/", InpSlowEMAPeriod,
         " auf ", EnumToString(_Period),
         " | Bias-EMA ", InpBiasEMAPeriod, " auf ", EnumToString(InpBiasTF),
         " | Long ", (InpAllowLong ? "an" : "aus"),
         " | Short ", (InpAllowShort ? "an" : "aus"));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Aufraeumen                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_fastEMA != INVALID_HANDLE) IndicatorRelease(h_fastEMA);
   if(h_slowEMA != INVALID_HANDLE) IndicatorRelease(h_slowEMA);
   if(h_atr     != INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_rsi     != INVALID_HANDLE) IndicatorRelease(h_rsi);
   if(h_biasEMA != INVALID_HANDLE) IndicatorRelease(h_biasEMA);
  }

//+------------------------------------------------------------------+
//| Haupt-Tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Tageswechsel + Tagesverlust-Stopp
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   if(now.day_of_year != m_last_day)
     {
      m_last_day          = now.day_of_year;
      m_loss_limit_active = false;
      m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
     }
   if(CheckDailyLossLimit())
     {
      if(!m_loss_limit_active)
        {
         m_loss_limit_active = true;
         Print("Tagesverlust-Limit erreicht. Schliesse alles, Pause bis morgen.");
         CloseMyPositions();
        }
      return;
     }

   // 2. Position dieses EA finden (Typ merken)
   bool  hasPos = false;
   ulong ticket = 0;
   long  posType = -1;
   double posSL = 0.0, posTP = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
        {
         hasPos  = true;
         ticket  = PositionGetInteger(POSITION_TICKET);
         posType = PositionGetInteger(POSITION_TYPE);
         posSL   = PositionGetDouble(POSITION_SL);
         posTP   = PositionGetDouble(POSITION_TP);
         break;
        }
     }

   // 3. ATR (bei jedem Tick fuer Trailing) holen
   double atrNow[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atrNow) < 1) return;
   double atrValue = atrNow[0];

   // 4. Trailing-Stop (bei jedem Tick, damit er sauber mitzieht)
   if(hasPos && InpUseTrailing && atrValue > 0.0)
      ManageTrailingStop(ticket, posType, posSL, posTP, atrValue);

   // 5. Signale nur einmal je neuer Kerze auswerten
   datetime barTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(barTime == m_last_bar_time) return;

   double fast[3], slow[3], rsi[2];
   if(CopyBuffer(h_fastEMA, 0, 0, 3, fast) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slow) < 3)
      return;
   if(InpUseRSIFilter)
      if(CopyBuffer(h_rsi, 0, 0, 2, rsi) < 2) return;

   // Bias der hoeheren Zeitebene bestimmen
   double biasEMA[1];
   if(CopyBuffer(h_biasEMA, 0, 1, 1, biasEMA) < 1) return;
   double biasClose = iClose(_Symbol, InpBiasTF, 1);
   if(biasClose <= 0.0) return;
   bool biasUp   = (biasClose > biasEMA[0]);
   bool biasDown = (biasClose < biasEMA[0]);

   m_last_bar_time = barTime;
   if(atrValue <= 0.0) return;

   bool crossUp   = (fast[1] > slow[1]) && (fast[2] <= slow[2]); // Golden Cross
   bool crossDown = (fast[1] < slow[1]) && (fast[2] >= slow[2]); // Death Cross

   double rsiVal = InpUseRSIFilter ? rsi[1] : 50.0;
   bool rsiOkLong  = !InpUseRSIFilter || (rsiVal < InpRSIUpper);
   bool rsiOkShort = !InpUseRSIFilter || (rsiVal > InpRSILower);

   // 6. Offene Position verwalten: Ausstieg beim Gegenkreuz
   if(hasPos)
     {
      if(posType == POSITION_TYPE_BUY && crossDown)
        {
         Print("Long-Ausstieg: Death Cross. #", ticket);
         trade.PositionClose(ticket);
        }
      else if(posType == POSITION_TYPE_SELL && crossUp)
        {
         Print("Short-Ausstieg: Golden Cross. #", ticket);
         trade.PositionClose(ticket);
        }
      return;
     }

   // 7. Einstieg (nur wenn keine Position und kein Tagesstopp)
   if(m_loss_limit_active) return;

   if(InpAllowLong && crossUp && biasUp && rsiOkLong)
      OpenTrade(true, atrValue);
   else if(InpAllowShort && crossDown && biasDown && rsiOkShort)
      OpenTrade(false, atrValue);
  }

//+------------------------------------------------------------------+
//| Oeffnet eine Position (isLong=true -> Long, sonst Short)         |
//+------------------------------------------------------------------+
void OpenTrade(bool isLong, double atrValue)
  {
   double slPrice, entry, riskDistance, tpPrice;
   double stopsLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   if(isLong)
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      int shift = iLowest(_Symbol, _Period, MODE_LOW, InpSwingLookback, 1);
      if(shift < 0) return;
      double swingLow = iLow(_Symbol, _Period, shift);
      slPrice = swingLow - atrValue * InpATRBufferMult;
      if(slPrice > entry - stopsLevel) slPrice = entry - stopsLevel;
      slPrice = NormalizeDouble(slPrice, _Digits);
      riskDistance = entry - slPrice;
      if(riskDistance <= 0.0) { Print("Long: ungueltiger SL-Abstand."); return; }
      tpPrice = NormalizeDouble(entry + riskDistance * InpRewardRatio, _Digits);
     }
   else
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      int shift = iHighest(_Symbol, _Period, MODE_HIGH, InpSwingLookback, 1);
      if(shift < 0) return;
      double swingHigh = iHigh(_Symbol, _Period, shift);
      slPrice = swingHigh + atrValue * InpATRBufferMult;
      if(slPrice < entry + stopsLevel) slPrice = entry + stopsLevel;
      slPrice = NormalizeDouble(slPrice, _Digits);
      riskDistance = slPrice - entry;
      if(riskDistance <= 0.0) { Print("Short: ungueltiger SL-Abstand."); return; }
      tpPrice = NormalizeDouble(entry - riskDistance * InpRewardRatio, _Digits);
     }

   double lots = InpLotSize;
   if(InpUseRiskLots) lots = CalcRiskLots(riskDistance);
   if(lots <= 0.0) { Print("Lotgroesse 0 - Einstieg abgebrochen."); return; }

   string txt = isLong ? "EMA MTF Long" : "EMA MTF Short";
   Print(isLong ? "LONG" : "SHORT", " | Entry ", DoubleToString(entry, _Digits),
         " | SL ", DoubleToString(slPrice, _Digits),
         " | TP ", DoubleToString(tpPrice, _Digits),
         " | Lots ", DoubleToString(lots, 2));

   bool ok = isLong ? trade.Buy(lots, _Symbol, entry, slPrice, tpPrice, txt)
                    : trade.Sell(lots, _Symbol, entry, slPrice, tpPrice, txt);
   if(!ok)
      Print("Order fehlgeschlagen! Code: ", trade.ResultRetcode(),
            " - ", trade.ResultRetcodeDescription());
  }

//+------------------------------------------------------------------+
//| Zieht den Stop-Loss per ATR nach (beide Richtungen)              |
//+------------------------------------------------------------------+
void ManageTrailingStop(ulong ticket, long type, double curSL, double curTP, double atrValue)
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stopsLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   if(type == POSITION_TYPE_BUY)
     {
      double newSL = NormalizeDouble(bid - atrValue * InpTrailATRMult, _Digits);
      if(newSL > curSL && newSL < bid - stopsLevel)
         trade.PositionModify(ticket, newSL, curTP);
     }
   else if(type == POSITION_TYPE_SELL)
     {
      double newSL = NormalizeDouble(ask + atrValue * InpTrailATRMult, _Digits);
      if((curSL <= 0.0 || newSL < curSL) && newSL > ask + stopsLevel)
         trade.PositionModify(ticket, newSL, curTP);
     }
  }

//+------------------------------------------------------------------+
//| Prueft ob das Tagesverlust-Limit erreicht ist                    |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
  {
   double equity    = AccountInfoDouble(ACCOUNT_EQUITY);
   double daily_pnl = equity - m_day_start_balance;
   if(daily_pnl < 0 && m_day_start_balance > 0)
     {
      double loss_pct = (MathAbs(daily_pnl) / m_day_start_balance) * 100.0;
      if(loss_pct >= InpDailyLossLimit) return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Schliesst alle Positionen dieses EA                              |
//+------------------------------------------------------------------+
void CloseMyPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
         trade.PositionClose(PositionGetInteger(POSITION_TICKET));
     }
  }

//+------------------------------------------------------------------+
//| Risikobasierte Lotgroesse (SL-Treffer kostet InpRiskPerTradePct%)|
//+------------------------------------------------------------------+
double CalcRiskLots(double riskDistance)
  {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (InpRiskPerTradePct / 100.0);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0) return(InpLotSize);

   double lossPerLot = (riskDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0) return(InpLotSize);

   double lots    = riskMoney / lossPerLot;
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(lotStep > 0.0) lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return(lots);
  }

//+------------------------------------------------------------------+
//| Schreibt am Testende die Kennzahlen fuer die Auto-Auswertung     |
//+------------------------------------------------------------------+
double OnTester()
  {
   double profit      = TesterStatistics(STAT_PROFIT);
   double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss   = TesterStatistics(STAT_GROSS_LOSS);
   double profitFac   = TesterStatistics(STAT_PROFIT_FACTOR);
   double expPayoff   = TesterStatistics(STAT_EXPECTED_PAYOFF);
   double sharpe      = TesterStatistics(STAT_SHARPE_RATIO);
   double balDDpct    = TesterStatistics(STAT_BALANCEDD_PERCENT);
   double eqDDpct     = TesterStatistics(STAT_EQUITYDD_PERCENT);
   double trades      = TesterStatistics(STAT_TRADES);
   double winTrades   = TesterStatistics(STAT_PROFIT_TRADES);
   double lossTrades  = TesterStatistics(STAT_LOSS_TRADES);
   double conLossCnt  = TesterStatistics(STAT_CONLOSSMAX_TRADES);

   double winRate = (trades > 0)     ? (winTrades / trades * 100.0) : 0.0;
   double avgWin  = (winTrades > 0)  ? (grossProfit / winTrades)    : 0.0;
   double avgLoss = (lossTrades > 0) ? (grossLoss / lossTrades)     : 0.0;

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "timeframe="      + EnumToString((ENUM_TIMEFRAMES)_Period));
      FileWrite(h, "bias_tf="        + EnumToString(InpBiasTF));
      FileWrite(h, "net_profit="     + DoubleToString(profit, 2));
      FileWrite(h, "profit_factor="  + DoubleToString(profitFac, 2));
      FileWrite(h, "expected_payoff="+ DoubleToString(expPayoff, 2));
      FileWrite(h, "sharpe="         + DoubleToString(sharpe, 2));
      FileWrite(h, "balance_dd_pct=" + DoubleToString(balDDpct, 2));
      FileWrite(h, "equity_dd_pct="  + DoubleToString(eqDDpct, 2));
      FileWrite(h, "trades="         + DoubleToString(trades, 0));
      FileWrite(h, "win_rate_pct="   + DoubleToString(winRate, 2));
      FileWrite(h, "avg_win="        + DoubleToString(avgWin, 2));
      FileWrite(h, "avg_loss="       + DoubleToString(avgLoss, 2));
      FileWrite(h, "max_conloss_count=" + DoubleToString(conLossCnt, 0));
      FileClose(h);
     }
   return(profit);
  }
//+------------------------------------------------------------------+
