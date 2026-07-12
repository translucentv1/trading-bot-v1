//+------------------------------------------------------------------+
//|                                 ema_9_21_crossover_long_v2.mq5   |
//|                                Philipp Behnisch / Trading Studio |
//|                                             https://ai.studio/   |
//+------------------------------------------------------------------+
#property copyright "Philipp Behnisch / Trading Studio"
#property link      "https://ai.studio/"
#property version   "2.00"
#property description "EMA-9/21-Crossover Long-Only Expert Advisor - PROFITABLE VERSION"
#property description "Mit Marktstruktur-Stop, dynamischem TP, ATR-Trailing und RSI-Filter."

// Trade-Bibliothek importieren
#include <Trade\Trade.mqh>
CTrade trade;

//--- Input Parameter
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = 9;       // Perioden schnelle EMA (Standard: 9)
input int      InpSlowEMAPeriod  = 21;      // Perioden langsame EMA (Standard: 21)

input group "--- Trend-Filter & RSI ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)
input int      InpRSIPeriod      = 14;      // RSI Periode
input double   InpRSIMaxLevel    = 70.0;    // Max RSI Level fuer Kauf (Ueberkauft-Filter)

input group "--- Risikomanagement (Struktur) ---"
input double   InpRiskPerTradePct = 1.0;    // Risiko pro Trade (% vom Kapital)
input int      InpSwingLookback   = 10;     // Lookback fuer Swing-Tief (Marktstruktur)
input int      InpATRPeriod       = 14;     // ATR Periode fuer Volatilitaetsmessung
input double   InpATRMult         = 1.5;    // ATR Multiplikator fuer SL-Puffer
input double   InpRewardRatio     = 1.8;    // Risk-to-Reward Ratio (TP = Risiko * Ratio)
input double   InpDailyLossLimit  = 5.0;    // Tagesverlust-Limit in % vom Kontostand

input group "--- Trailing Stop ---"
input bool     InpUseTrailing     = true;   // Trailing-Stop aktivieren
input double   InpTrailATRMult    = 2.5;    // ATR Multiplikator fuer Trailing-SL

input group "--- System Einstellungen ---"
input ulong    InpMagicNumber    = 123456;  // Magic Number fuer Identifikation
input int      InpSlippage       = 3;       // Maximaler Slippage (Pips)

//--- Globale Variablen
int      h_fastEMA;           // Handle fuer schnelle EMA
int      h_slowEMA;           // Handle fuer langsame EMA
int      h_trendEMA;          // Handle fuer Trend-Filter EMA
int      h_rsi;               // Handle fuer RSI
int      h_atr;               // Handle fuer ATR
datetime m_last_bar_time;     // Speichert die Zeit der letzten Kerze
bool     m_loss_limit_active; // Flag, ob das Tages-Verlustlimit erreicht wurde
int      m_last_day;          // Tag des Jahres zur Zuruecksetzung des Verlustlimits
double   m_day_start_balance; // Kontostand am Anfang des Handelstages

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Setzen der Magic Number fuer unsere Trade-Instanz
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   // Indikatoren initialisieren
   h_fastEMA = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_fastEMA == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des schnellen EMA Handles!");
      return(INIT_FAILED);
     }

   h_slowEMA = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_slowEMA == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des langsamen EMA Handles!");
      return(INIT_FAILED);
     }

   h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(h_rsi == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des RSI Handles!");
      return(INIT_FAILED);
     }

   h_atr = iATR(_Symbol, _Period, InpATRPeriod);
   if(h_atr == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des ATR Handles!");
      return(INIT_FAILED);
     }

   h_trendEMA = INVALID_HANDLE;
   if(InpUseTrendFilter)
     {
      h_trendEMA = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(h_trendEMA == INVALID_HANDLE)
        {
         Print("Fehler beim Erstellen des Trend-EMA Handles!");
         return(INIT_FAILED);
        }
     }

   // Globale Variablen initialisieren
   m_last_bar_time     = 0;
   m_loss_limit_active = false;
   
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("EA v2.0 erfolgreich initialisiert.");
   Print("Tages-Startguthaben: ", DoubleToString(m_day_start_balance, 2), " EUR");
   Print("Tagesverlust-Limit: ", DoubleToString(InpDailyLossLimit, 1), "% (Max. Verlust: ", DoubleToString(m_day_start_balance * (InpDailyLossLimit/100.0), 2), " EUR)");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Indicator-Handles freigeben
   IndicatorRelease(h_fastEMA);
   IndicatorRelease(h_slowEMA);
   IndicatorRelease(h_rsi);
   IndicatorRelease(h_atr);
   if(h_trendEMA != INVALID_HANDLE)
     {
      IndicatorRelease(h_trendEMA);
     }
   Print("EA v2.0 deinitialisiert. Grund-Code: ", reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Check, ob ein neuer Tag angebrochen ist (zuruecksetzen des Tagesverlusts)
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
   if(current_time.day_of_year != m_last_day)
     {
      m_last_day          = current_time.day_of_year;
      m_loss_limit_active = false;
      m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      Print("Neuer Handelstag angebrochen. Verlustlimit zurueckgesetzt.");
      Print("Neuer Tages-Startguthaben: ", DoubleToString(m_day_start_balance, 2), " EUR");
     }

   // 2. Tagesverlust-Limit ueberpruefen
   if(CheckDailyLossLimit())
     {
      if(!m_loss_limit_active)
        {
         m_loss_limit_active = true;
         Print("WARNUNG: Tagesverlust-Limit ueberschritten! Alle Positionen werden geschlossen.");
         CloseAllPositions();
        }
      return; // Kein weiterer Handel heute
     }

   // 3. Trailing Stop verwalten (falls aktiv)
   if(InpUseTrailing)
     {
      ManageTrailingStop();
     }

   // 4. Auf neue Kerze pruefen (EMA-Crossover wird fuer Stabilitaet auf Schlusskursen berechnet)
   datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(current_bar_time == m_last_bar_time)
     {
      return; // Wir berechnen Signale nur einmal pro neuer Kerze
     }

   // 5. Indikator-Werte abfragen
   double fastEMA[3];
   double slowEMA[3];
   double trendEMA[3];
   double rsi[2];

   if(CopyBuffer(h_fastEMA, 0, 0, 3, fastEMA) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slowEMA) < 3 ||
      CopyBuffer(h_rsi, 0, 1, 2, rsi) < 2)
     {
      Print("Fehler beim Kopieren der Indikator-Werte!");
      return;
     }

   if(InpUseTrendFilter && h_trendEMA != INVALID_HANDLE)
     {
      if(CopyBuffer(h_trendEMA, 0, 0, 3, trendEMA) < 3)
        {
         Print("Fehler beim Kopieren des Trend-EMA-Wertes!");
         return;
        }
     }

   // Wenn wir erfolgreich die Werte kopiert haben, merken wir uns die Bar-Zeit
   m_last_bar_time = current_bar_time;

   // 6. Signalpruefung (Long-Only)
   // Schnelle EMA kreuzt Langsame EMA nach oben auf den letzten geschlossenen Kerzen
   bool isGoldenCross = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   
   // Schnelle EMA kreuzt Langsame EMA nach unten (Ausstiegssignal)
   bool isDeathCross  = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   // Trend-Bedingung: Nur kaufen, wenn die schnelle EMA ueber der Trend-EMA liegt (Aufwaertstrend)
   bool isTrendUp = true;
   if(InpUseTrendFilter && h_trendEMA != INVALID_HANDLE)
     {
      isTrendUp = (fastEMA[1] > trendEMA[1]);
     }

   // RSI Ueberkauft-Filter: Nicht kaufen wenn RSI > MaxLevel (z.B. 70)
   bool isRsiNotOverbought = (rsi[0] < InpRSIMaxLevel);

   // Pruefen, ob wir bereits eine offene Position haben (mit Magic Number)
   bool hasOpenPosition = false;
   ulong ticket = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            hasOpenPosition = true;
            ticket = PositionGetInteger(POSITION_TICKET);
            break;
           }
        }
     }

   // 7. Trading Logik ausfuehren
   if(hasOpenPosition)
     {
      // Wenn wir ein Ausstiegssignal (Death Cross) erhalten, schliessen wir die Long-Position
      if(isDeathCross)
        {
         Print("Ausstiegssignal: EMA-Kreuzung nach unten. Schliesse Position #", ticket);
         trade.PositionClose(ticket);
        }
     }
   else
     {
      // Wenn wir ein Einstiegssignal (Golden Cross) erhalten, alle Filter gruen sind und kein Tagesverlust aktiv ist
      if(isGoldenCross && isTrendUp && isRsiNotOverbought && !m_loss_limit_active)
        {
         OpenLongPosition();
        }
     }
  }

//+------------------------------------------------------------------+
//| Berechnet und ueberprueft das Tagesverlust-Limit                 |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
  {
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double daily_pnl = current_equity - m_day_start_balance;
   
   if(daily_pnl < 0)
     {
      double loss_percent = (MathAbs(daily_pnl) / m_day_start_balance) * 100.0;
      if(loss_percent >= InpDailyLossLimit)
        {
         return true; // Limit ueberschritten
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Schliesst alle vom EA geoeffneten Positionen                     |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            Print("Schliesse Position #", ticket, " aufgrund von Tagesverlust-Stopp.");
            trade.PositionClose(ticket);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Verwaltet den ATR-basierten Trailing-Stop fuer offene Positionen |
//+------------------------------------------------------------------+
void ManageTrailingStop()
  {
   double atr[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atr) < 1) return;

   double trailing_distance = atr[0] * InpTrailATRMult;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            double current_sl = PositionGetDouble(POSITION_SL);
            double current_tp = PositionGetDouble(POSITION_TP);
            
            // Neuer Trailing SL
            double target_sl = NormalizeDouble(bid - trailing_distance, _Digits);
            
            // Nur nachziehen (SL kann bei Long nur STEIGEN)
            if(target_sl > current_sl && target_sl < bid - (10 * _Point))
              {
               if(!trade.PositionModify(ticket, target_sl, current_tp))
                 {
                  Print("Fehler beim Trailing-Stop fuer Position #", ticket, ": ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
                 }
               else
                 {
                  Print("Trailing SL angepasst fuer Position #", ticket, " auf ", DoubleToString(target_sl, _Digits));
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Oeffnet eine neue Long-Position mit risikobasierter Lotgroesse   |
//+------------------------------------------------------------------+
void OpenLongPosition()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   // 1. Marktstruktur-SL ermitteln (Swing Low der letzten X Kerzen)
   double lows[];
   ArraySetAsSeries(lows, true);
   if(CopyLow(_Symbol, _Period, 1, InpSwingLookback, lows) < InpSwingLookback)
     {
      Print("Fehler beim Kopieren der Low-Preise fuer Marktstruktur-SL!");
      return;
     }

   double lowest_low = lows[0];
   for(int i = 1; i < InpSwingLookback; i++)
     {
      if(lows[i] < lowest_low)
        {
         lowest_low = lows[i];
        }
     }

   // ATR fuer Puffer abfragen
   double atr[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atr) < 1)
     {
      Print("Fehler beim Kopieren des ATR-Wertes!");
      return;
     }

   double atr_buffer = atr[0] * InpATRMult;
   double sl_price = NormalizeDouble(lowest_low - atr_buffer, _Digits);

   // Sicherheits-Check: SL muss unter dem Einstieg liegen
   if(sl_price >= ask)
     {
      sl_price = NormalizeDouble(ask - (atr[0] * 2.0), _Digits); // Fallback auf 2x ATR falls ungueltige Struktur
     }

   // 2. Dynamischen TP berechnen (Risiko * RewardRatio)
   double sl_distance = ask - sl_price;
   double tp_distance = sl_distance * InpRewardRatio;
   double tp_price = NormalizeDouble(ask + tp_distance, _Digits);

   // 3. Risikobasierte Lotgroesse berechnen (1 SL Treffer = genau X% Risiko)
   double risk_amount = balance * (InpRiskPerTradePct / 100.0);
   
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tick_size <= 0 || tick_value <= 0)
     {
      Print("Fehler bei Symbol-Informationen!");
      return;
     }

   // Lots berechnen: Risk_Amount / (SL_Distance * (Tick_Value / Tick_Size))
   double value_per_point = tick_value / tick_size;
   double calculated_lots = risk_amount / (sl_distance * value_per_point);

   // Lotgroesse an Broker-Spezifikationen anpassen (Runden auf Volume Step)
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   calculated_lots = MathFloor(calculated_lots / lot_step) * lot_step;
   
   if(calculated_lots < min_lot) calculated_lots = min_lot;
   if(calculated_lots > max_lot) calculated_lots = max_lot;

   // 4. Kauf ausfuehren
   Print("Kaufe risikobasiert: ", DoubleToString(calculated_lots, 2), " Lots bei ", DoubleToString(ask, _Digits));
   Print("Risiko: ", DoubleToString(risk_amount, 2), " EUR (SL: ", DoubleToString(sl_price, _Digits), ")");
   Print("Ziel: ", DoubleToString(risk_amount * InpRewardRatio, 2), " EUR (TP: ", DoubleToString(tp_price, _Digits), ")");

   if(!trade.Buy(calculated_lots, _Symbol, ask, sl_price, tp_price, "EMA Crossover Long v2.0"))
     {
      Print("Kauf-Order v2.0 fehlgeschlagen! Fehlercode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Kauf-Order v2.0 erfolgreich ausgefuehrt. Ticket: ", trade.ResultOrder());
     }
  }

//+------------------------------------------------------------------+
//| Wird am Ende jedes Strategy-Tester-Laufs aufgerufen. Schreibt    |
//| die wichtigsten Kennzahlen nach Common\Files\tester_result.txt,  |
//| damit sie automatisiert ausgelesen werden koennen.               |
//+------------------------------------------------------------------+
double OnTester()
  {
   double profit      = TesterStatistics(STAT_PROFIT);
   double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss   = TesterStatistics(STAT_GROSS_LOSS);
   double profitFac   = TesterStatistics(STAT_PROFIT_FACTOR);
   double expPayoff   = TesterStatistics(STAT_EXPECTED_PAYOFF);
   double recovery    = TesterStatistics(STAT_RECOVERY_FACTOR);
   double sharpe      = TesterStatistics(STAT_SHARPE_RATIO);
   double balDD       = TesterStatistics(STAT_BALANCE_DD);
   double balDDpct    = TesterStatistics(STAT_BALANCEDD_PERCENT);
   double eqDD        = TesterStatistics(STAT_EQUITY_DD);
   double eqDDpct     = TesterStatistics(STAT_EQUITYDD_PERCENT);
   double trades      = TesterStatistics(STAT_TRADES);
   double winTrades   = TesterStatistics(STAT_PROFIT_TRADES);
   double lossTrades  = TesterStatistics(STAT_LOSS_TRADES);
   double maxWin      = TesterStatistics(STAT_MAX_PROFITTRADE);
   double maxLoss     = TesterStatistics(STAT_MAX_LOSSTRADE);
   double conLossMax  = TesterStatistics(STAT_CONLOSSMAX);
   double conLossCnt  = TesterStatistics(STAT_CONLOSSMAX_TRADES);

   double winRate = (trades > 0)     ? (winTrades / trades * 100.0) : 0.0;
   double avgWin  = (winTrades > 0)  ? (grossProfit / winTrades)    : 0.0;
   double avgLoss = (lossTrades > 0) ? (grossLoss / lossTrades)     : 0.0;

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "symbol="         + _Symbol);
      FileWrite(h, "timeframe="      + EnumToString((ENUM_TIMEFRAMES)_Period));
      FileWrite(h, "net_profit="     + DoubleToString(profit, 2));
      FileWrite(h, "gross_profit="   + DoubleToString(grossProfit, 2));
      FileWrite(h, "gross_loss="     + DoubleToString(grossLoss, 2));
      FileWrite(h, "profit_factor="  + DoubleToString(profitFac, 2));
      FileWrite(h, "expected_payoff="+ DoubleToString(expPayoff, 2));
      FileWrite(h, "recovery_factor="+ DoubleToString(recovery, 2));
      FileWrite(h, "sharpe="         + DoubleToString(sharpe, 2));
      FileWrite(h, "balance_dd="     + DoubleToString(balDD, 2));
      FileWrite(h, "balance_dd_pct=" + DoubleToString(balDDpct, 2));
      FileWrite(h, "equity_dd="      + DoubleToString(eqDD, 2));
      FileWrite(h, "equity_dd_pct="  + DoubleToString(eqDDpct, 2));
      FileWrite(h, "trades="         + DoubleToString(trades, 0));
      FileWrite(h, "win_trades="     + DoubleToString(winTrades, 0));
      FileWrite(h, "loss_trades="    + DoubleToString(lossTrades, 0));
      FileWrite(h, "win_rate_pct="   + DoubleToString(winRate, 2));
      FileWrite(h, "avg_win="        + DoubleToString(avgWin, 2));
      FileWrite(h, "avg_loss="       + DoubleToString(avgLoss, 2));
      FileWrite(h, "max_win="        + DoubleToString(maxWin, 2));
      FileWrite(h, "max_loss="       + DoubleToString(maxLoss, 2));
      FileWrite(h, "max_conloss_money=" + DoubleToString(conLossMax, 2));
      FileWrite(h, "max_conloss_count=" + DoubleToString(conLossCnt, 0));
      FileClose(h);
     }

   return(profit);
  }
//+------------------------------------------------------------------+
