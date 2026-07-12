//+------------------------------------------------------------------+
//| EMA 9/21 Crossover (Long only) - v2.0                            |
//| Market-Structure-Stop, dynamischer Take-Profit, ATR & RSI        |
//|                                                                  |
//| Kurzbeschreibung der Strategie:                                  |
//|  EINSTIEG (nur Long):                                            |
//|   - EMA 9 kreuzt EMA 21 von unten nach oben (Golden Cross)       |
//|   - Trend bestaetigt: EMA 9 liegt ueber EMA 200 (optional)       |
//|   - RSI ist NICHT ueberkauft (optional, Standard < 70)           |
//|  RISIKO / MARKTSTRUKTUR:                                         |
//|   - Stop-Loss unter das letzte Swing-Tief (Markttief der         |
//|     letzten N Kerzen), mit einem ATR-Puffer darunter.            |
//|     -> Der Stop richtet sich nach der echten Marktstruktur,      |
//|        nicht nach einem starren Prozentwert.                     |
//|   - Lotgroesse wird so berechnet, dass ein Stop-Treffer genau    |
//|     InpRiskPerTradePct % vom Kapital kostet (risikobasiert).     |
//|  DYNAMISCHER AUSSTIEG:                                           |
//|   - Take-Profit = Risiko x InpRewardRatio (passt sich dem        |
//|     Stop-Abstand automatisch an).                                |
//|   - ATR-Trailing-Stop zieht den Stop bei Gewinn nach.            |
//|   - Zusaetzlich Ausstieg beim Gegenkreuz (EMA 9 unter EMA 21).   |
//|  SCHUTZ:                                                         |
//|   - Tagesverlust-Limit schliesst alles und pausiert bis morgen.  |
//|                                                                  |
//| Nur fuer Demo-/Paper-Trading. Kompilieren (F7) und Strategy      |
//| Tester laufen im MetaEditor/MT5 beim Nutzer.                     |
//+------------------------------------------------------------------+
#property copyright "Phase 2 - Demo/Paper"
#property version   "2.00"
#property strict
#property description "EMA-9/21-Crossover Long-Only mit Market-Structure-Stop,"
#property description "dynamischem Take-Profit (ATR-Trailing) und RSI-Filter."

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Indikatoren ------------------------------------------
input group "--- Signal-EMAs ---"
input int      InpFastEMAPeriod  = 9;       // Perioden schnelle EMA
input int      InpSlowEMAPeriod  = 21;      // Perioden langsame EMA

//--- Eingaben: Trendfilter ------------------------------------------
input group "--- Trend-Filter (EMA 200) ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-EMA

//--- Eingaben: RSI-Filter -------------------------------------------
input group "--- RSI-Filter (kein Kauf wenn ueberkauft) ---"
input bool     InpUseRSIFilter   = true;    // RSI-Filter aktivieren
input int      InpRSIPeriod      = 14;      // Perioden RSI
input double   InpRSIMaxLevel    = 70.0;    // Kein Kauf wenn RSI darueber

//--- Eingaben: Marktstruktur (Stop-Loss) ----------------------------
input group "--- Marktstruktur / Stop-Loss ---"
input int      InpSwingLookback  = 12;      // Kerzen zurueck fuer Swing-Tief
input int      InpATRPeriod      = 14;      // Perioden ATR (Volatilitaet)
input double   InpATRBufferMult  = 0.5;     // ATR-Puffer unter dem Swing-Tief

//--- Eingaben: Dynamischer Take-Profit / Trailing -------------------
input group "--- Take-Profit / Trailing ---"
input double   InpRewardRatio    = 1.8;     // TP = Risiko x diesem Faktor
input bool     InpUseTrailing    = true;    // ATR-Trailing-Stop aktivieren
input double   InpTrailATRMult   = 2.5;     // Trailing-Abstand in ATR

//--- Eingaben: Risiko / Position ------------------------------------
input group "--- Risiko / Position ---"
input bool     InpUseRiskLots    = true;    // Lot aus Risiko% berechnen
input double   InpRiskPerTradePct= 1.0;     // Risiko pro Trade (% vom Kapital)
input double   InpLotSize        = 0.10;    // Feste Lotgroesse (falls Risk aus)
input double   InpDailyLossLimit = 5.0;     // Tagesverlust-Limit (% vom Kapital)

//--- Eingaben: System ----------------------------------------------
input group "--- System ---"
input ulong    InpMagicNumber    = 123456;  // Magic Number
input int      InpSlippage       = 3;       // Max. Slippage (Punkte)

//--- Globale Variablen / Indikator-Handles --------------------------
int      h_fastEMA  = INVALID_HANDLE;
int      h_slowEMA  = INVALID_HANDLE;
int      h_trendEMA = INVALID_HANDLE;
int      h_atr      = INVALID_HANDLE;
int      h_rsi      = INVALID_HANDLE;

datetime m_last_bar_time;     // Zeit der zuletzt verarbeiteten Kerze
bool     m_loss_limit_active; // true = Tagesverlust erreicht, kein Handel
int      m_last_day;          // Tag des Jahres (Tageswechsel-Erkennung)
double   m_day_start_balance; // Kontostand am Tagesbeginn

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

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   h_fastEMA = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   h_slowEMA = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   h_atr     = iATR(_Symbol, _Period, InpATRPeriod);
   if(h_fastEMA == INVALID_HANDLE || h_slowEMA == INVALID_HANDLE || h_atr == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen der Indikator-Handles (EMA/ATR)!");
      return(INIT_FAILED);
     }

   if(InpUseTrendFilter)
     {
      h_trendEMA = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(h_trendEMA == INVALID_HANDLE)
        {
         Print("Fehler beim Erstellen des Trend-EMA Handles!");
         return(INIT_FAILED);
        }
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

   Print("EA v2.0 gestartet: EMA ", InpFastEMAPeriod, "/", InpSlowEMAPeriod,
         " | Trendfilter ", (InpUseTrendFilter ? "an" : "aus"),
         " | RSI-Filter ", (InpUseRSIFilter ? "an" : "aus"),
         " | Struktur-SL Lookback ", InpSwingLookback,
         " | TP-Faktor ", DoubleToString(InpRewardRatio, 1),
         " | Trailing ", (InpUseTrailing ? "an" : "aus"));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Aufraeumen                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_fastEMA  != INVALID_HANDLE) IndicatorRelease(h_fastEMA);
   if(h_slowEMA  != INVALID_HANDLE) IndicatorRelease(h_slowEMA);
   if(h_trendEMA != INVALID_HANDLE) IndicatorRelease(h_trendEMA);
   if(h_atr      != INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_rsi      != INVALID_HANDLE) IndicatorRelease(h_rsi);
  }

//+------------------------------------------------------------------+
//| Haupt-Tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Tageswechsel erkennen und Verlustlimit zuruecksetzen
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
   if(current_time.day_of_year != m_last_day)
     {
      m_last_day          = current_time.day_of_year;
      m_loss_limit_active = false;
      m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      Print("Neuer Handelstag. Verlustlimit zurueckgesetzt. Startguthaben: ",
            DoubleToString(m_day_start_balance, 2));
     }

   // 2. Tagesverlust-Limit pruefen (bei jedem Tick, Sicherheitsnetz)
   if(CheckDailyLossLimit())
     {
      if(!m_loss_limit_active)
        {
         m_loss_limit_active = true;
         Print("WARNUNG: Tagesverlust-Limit erreicht! Alle Positionen werden geschlossen.");
         CloseAllPositions();
        }
      return;
     }

   // 3. Nur einmal pro neuer (abgeschlossener) Kerze arbeiten
   datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(current_bar_time == m_last_bar_time)
      return;

   // 4. Indikator-Werte holen (Index 1 = letzte abgeschlossene Kerze)
   double fastEMA[3], slowEMA[3], trendEMA[3], atrBuf[2], rsiBuf[2];
   if(CopyBuffer(h_fastEMA, 0, 0, 3, fastEMA) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slowEMA) < 3 ||
      CopyBuffer(h_atr,     0, 0, 2, atrBuf)  < 2)
     {
      return; // Daten noch nicht bereit
     }

   if(InpUseTrendFilter)
      if(CopyBuffer(h_trendEMA, 0, 0, 3, trendEMA) < 3) return;

   if(InpUseRSIFilter)
      if(CopyBuffer(h_rsi, 0, 0, 2, rsiBuf) < 2) return;

   // Ab hier haben wir gueltige Daten -> Bar-Zeit merken
   m_last_bar_time = current_bar_time;

   double atrValue = atrBuf[1];
   if(atrValue <= 0.0) return;

   // 5. Signale berechnen (auf den letzten abgeschlossenen Kerzen)
   bool isGoldenCross = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   bool isDeathCross  = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   bool trendUp = true;
   if(InpUseTrendFilter)
      trendUp = (fastEMA[1] > trendEMA[1]);

   bool rsiOk = true;
   if(InpUseRSIFilter)
      rsiOk = (rsiBuf[1] < InpRSIMaxLevel);

   // 6. Offene Position dieses EA suchen
   bool  hasPos  = false;
   ulong ticket  = 0;
   double posSL  = 0.0, posTP = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
        {
         hasPos = true;
         ticket = PositionGetInteger(POSITION_TICKET);
         posSL  = PositionGetDouble(POSITION_SL);
         posTP  = PositionGetDouble(POSITION_TP);
         break;
        }
     }

   // 7. Position vorhanden -> Trailing-Stop + Gegenkreuz-Ausstieg
   if(hasPos)
     {
      if(InpUseTrailing)
         ManageTrailingStop(ticket, posSL, posTP, atrValue);

      if(isDeathCross)
        {
         Print("Ausstieg: EMA-Gegenkreuz nach unten. Schliesse #", ticket);
         trade.PositionClose(ticket);
        }
      return;
     }

   // 8. Keine Position -> Einstieg pruefen
   if(isGoldenCross && trendUp && rsiOk && !m_loss_limit_active)
      OpenLongPosition(atrValue);
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
      if(loss_pct >= InpDailyLossLimit)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Schliesst alle Positionen dieses EA                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
        {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         trade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//| Zieht den Stop-Loss bei Gewinn per ATR nach (nur nach oben)      |
//+------------------------------------------------------------------+
void ManageTrailingStop(ulong ticket, double curSL, double curTP, double atrValue)
  {
   double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stopsLevel= (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   // Neuer Stop = aktueller Kurs minus ATR-Abstand
   double newSL = NormalizeDouble(bid - atrValue * InpTrailATRMult, _Digits);

   // Nur nachziehen (nach oben) und nur wenn Mindestabstand zum Kurs passt
   if(newSL > curSL && newSL < bid - stopsLevel)
     {
      if(trade.PositionModify(ticket, newSL, curTP))
         Print("Trailing-Stop nachgezogen auf ", DoubleToString(newSL, _Digits));
     }
  }

//+------------------------------------------------------------------+
//| Oeffnet eine Long-Position: Struktur-SL, dynamischer TP, Risk-Lot|
//+------------------------------------------------------------------+
void OpenLongPosition(double atrValue)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // --- Stop-Loss aus der Marktstruktur (letztes Swing-Tief) -------
   int    lowestShift = iLowest(_Symbol, _Period, MODE_LOW, InpSwingLookback, 1);
   if(lowestShift < 0) return;
   double swingLow    = iLow(_Symbol, _Period, lowestShift);
   double slPrice     = swingLow - atrValue * InpATRBufferMult;

   // Mindestabstand des Brokers beachten (Stops-Level)
   double stopsLevel  = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double minSLprice  = ask - stopsLevel;
   if(slPrice > minSLprice)
      slPrice = minSLprice;

   slPrice = NormalizeDouble(slPrice, _Digits);
   double riskDistance = ask - slPrice;
   if(riskDistance <= 0.0)
     {
      Print("Ungueltiger Stop-Abstand, Einstieg abgebrochen.");
      return;
     }

   // --- Dynamischer Take-Profit: Risiko x Chance-Risiko-Verhaeltnis -
   double tpPrice = NormalizeDouble(ask + riskDistance * InpRewardRatio, _Digits);

   // --- Lotgroesse: risikobasiert oder fest ------------------------
   double lots = InpLotSize;
   if(InpUseRiskLots)
      lots = CalcRiskLots(riskDistance);
   if(lots <= 0.0)
     {
      Print("Lotgroesse 0 - Einstieg abgebrochen.");
      return;
     }

   Print("Kaufsignal (Golden Cross). Swing-Tief ", DoubleToString(swingLow, _Digits),
         " | Ask ", DoubleToString(ask, _Digits),
         " | SL ", DoubleToString(slPrice, _Digits),
         " | TP ", DoubleToString(tpPrice, _Digits),
         " | Lots ", DoubleToString(lots, 2),
         " | ATR ", DoubleToString(atrValue, _Digits));

   if(!trade.Buy(lots, _Symbol, ask, slPrice, tpPrice, "EMA v2 Long"))
      Print("Kauf fehlgeschlagen! Code: ", trade.ResultRetcode(),
            " - ", trade.ResultRetcodeDescription());
   else
      Print("Kauf ausgefuehrt. Ticket: ", trade.ResultOrder());
  }

//+------------------------------------------------------------------+
//| Berechnet die Lotgroesse so, dass ein SL-Treffer genau           |
//| InpRiskPerTradePct % vom Kapital kostet                          |
//+------------------------------------------------------------------+
double CalcRiskLots(double riskDistance)
  {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (InpRiskPerTradePct / 100.0);

   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0)
     {
      Print("Tick-Groesse/-Wert ungueltig - nutze feste Lotgroesse.");
      return(InpLotSize);
     }

   // Geldverlust je 1.0 Lot, wenn der Stop getroffen wird
   double lossPerLot = (riskDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0)
      return(InpLotSize);

   double lots = riskMoney / lossPerLot;

   // Auf erlaubte Lot-Schritte runden und in Grenzen halten
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(lotStep > 0.0)
      lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;

   return(lots);
  }

//+------------------------------------------------------------------+
//| Wird am Ende jedes Strategy-Tester-Laufs aufgerufen. Schreibt    |
//| die wichtigsten Kennzahlen als Textdatei in den gemeinsamen      |
//| Dateiordner (Common\Files\tester_result.txt), damit sie          |
//| automatisiert ausgelesen werden koennen.                         |
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

   double winRate = (trades > 0)     ? (winTrades / trades * 100.0)   : 0.0;
   double avgWin  = (winTrades > 0)  ? (grossProfit / winTrades)      : 0.0;
   double avgLoss = (lossTrades > 0) ? (grossLoss / lossTrades)       : 0.0;

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "symbol="        + _Symbol);
      FileWrite(h, "timeframe="     + EnumToString((ENUM_TIMEFRAMES)_Period));
      FileWrite(h, "net_profit="    + DoubleToString(profit, 2));
      FileWrite(h, "gross_profit="  + DoubleToString(grossProfit, 2));
      FileWrite(h, "gross_loss="    + DoubleToString(grossLoss, 2));
      FileWrite(h, "profit_factor=" + DoubleToString(profitFac, 2));
      FileWrite(h, "expected_payoff="+ DoubleToString(expPayoff, 2));
      FileWrite(h, "recovery_factor="+ DoubleToString(recovery, 2));
      FileWrite(h, "sharpe="        + DoubleToString(sharpe, 2));
      FileWrite(h, "balance_dd="    + DoubleToString(balDD, 2));
      FileWrite(h, "balance_dd_pct="+ DoubleToString(balDDpct, 2));
      FileWrite(h, "equity_dd="     + DoubleToString(eqDD, 2));
      FileWrite(h, "equity_dd_pct=" + DoubleToString(eqDDpct, 2));
      FileWrite(h, "trades="        + DoubleToString(trades, 0));
      FileWrite(h, "win_trades="    + DoubleToString(winTrades, 0));
      FileWrite(h, "loss_trades="   + DoubleToString(lossTrades, 0));
      FileWrite(h, "win_rate_pct="  + DoubleToString(winRate, 2));
      FileWrite(h, "avg_win="       + DoubleToString(avgWin, 2));
      FileWrite(h, "avg_loss="      + DoubleToString(avgLoss, 2));
      FileWrite(h, "max_win="       + DoubleToString(maxWin, 2));
      FileWrite(h, "max_loss="      + DoubleToString(maxLoss, 2));
      FileWrite(h, "max_conloss_money=" + DoubleToString(conLossMax, 2));
      FileWrite(h, "max_conloss_count=" + DoubleToString(conLossCnt, 0));
      FileClose(h);
     }

   return(profit);
  }
//+------------------------------------------------------------------+
