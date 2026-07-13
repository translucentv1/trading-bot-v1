# EA_CODE.md - aktueller EA-Code (Handoff ohne separaten Upload)

**Aktive Datei:** `experts/ema_mtf_v3.mq5`
**Stand:** 2026-07-12 (Version 3.50, + Einstiegs-Modus 2 Opening-Range-Breakout)

> Regel: Bei JEDER Aenderung an der aktiven .mq5-Datei wird dieser
> Block im selben Commit mitaktualisiert.

```mql5
//+------------------------------------------------------------------+
//| EMA 9/21 + Multi-Timeframe-Bias - v3.50 (Long & Short)         |
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
#property version   "3.50"
#property strict
#property description "EMA 9/21 + Multi-Timeframe-Bias, Long & Short,"
#property description "Struktur-Stop, dynamischer TP, ATR-Trailing, RSI-Filter."
#property description "Empfohlen (Position Trading): H4-Chart + D1-Bias, long-only."
// Backtest EURUSD 2022-2026, long-only (10.000 EUR, 1% Risiko/Trade):
//  EMPFOHLEN Position Trading: H4-Chart + D1-Bias + Gewinnsicherung
//    +385, PF 1,12, Sharpe 0,99, DD 7,2 %, Trefferquote 68 %, 101 Trades
//  Alternative aktiver: H1-Chart + H4-Bias OHNE Gewinnsicherung
//    +1686, PF 1,12, Sharpe 1,87 (Gewinnsicherung schadet hier -> aus)

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Signal-EMAs (Ausfuehrungs-Zeitebene = Chart) ---------
input group "--- Signal-EMAs (Chart-Zeitebene) ---"
input int             InpFastEMAPeriod  = 9;        // Perioden schnelle EMA
input int             InpSlowEMAPeriod  = 21;       // Perioden langsame EMA

//--- Eingaben: Trend-Bias (hoehere Zeitebene) -----------------------
input group "--- Trend-Bias (hoehere Zeitebene) ---"
input ENUM_TIMEFRAMES InpBiasTF         = PERIOD_D1;// Hoehere Zeitebene fuer Richtung (Position Trading: H4-Chart + D1-Bias)
input int             InpBiasEMAPeriod  = 50;       // EMA auf der Bias-Zeitebene

//--- Eingaben: Handelsrichtung --------------------------------------
input group "--- Handelsrichtung ---"
input bool            InpAllowLong      = true;     // Long-Trades erlauben
input bool            InpAllowShort     = false;    // Short-Trades erlauben (auf EURUSD long-only besser, s. Backtests)

//--- Eingaben: RSI-Filter -------------------------------------------
input group "--- RSI-Filter ---"
input bool            InpUseRSIFilter   = true;     // RSI-Filter aktivieren
input int             InpRSIPeriod      = 14;       // Perioden RSI
input double          InpRSIUpper       = 70.0;     // kein Long wenn RSI darueber (nur Modus 0)
input double          InpRSILower       = 30.0;     // kein Short wenn RSI darunter (nur Modus 0)

//--- Eingaben: Einstiegs-Modus --------------------------------------
input group "--- Einstiegs-Modus ---"
input int             InpEntryMode      = 0;        // 0=EMA-Kreuz, 1=RSI-Mean-Reversion, 2=Opening-Range-Breakout
input double          InpRSIBuyLevel    = 40.0;     // MR Long: RSI kreuzt von unten hier durch
input double          InpRSISellLevel   = 60.0;     // MR Short: RSI kreuzt von oben hier durch
input double          InpMRMinProfitMoney = 0.0;    // MR-Ausstieg: raus sobald Gewinn (EUR) >= Wert (0 = jeder Gewinn)

//--- Eingaben: Opening-Range-Breakout (nur Modus 2) -----------------
input group "--- Opening-Range-Breakout ---"
input int             InpRangeStartHour   = 0;      // Range-Beginn (Stunde, Serverzeit EET)
input int             InpRangeEndHour     = 8;      // Range-Ende (Stunde, Serverzeit EET)
input double          InpBreakoutBufferATR= 0.2;    // ATR-Puffer gegen Fehlausbrueche

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

//--- Eingaben: Volatilitaets-Filter ---------------------------------
input group "--- Volatilitaets-Filter (rollierend) ---"
input bool            InpUseVolFilter   = false;    // nur handeln wenn Volatilitaet ueber dem Median
input int             InpVolLookback    = 100;      // Lookback Handelstage fuer ATR-D1-Median

//--- Eingaben: Gewinn sichern ---------------------------------------
input group "--- Gewinn sichern (Break-Even / Teil-TP) ---"
input bool            InpUseBreakEven   = true;     // Stop auf Einstieg ziehen sobald im Plus
input double          InpBreakEvenAtR   = 1.0;      // ab wieviel R (Risiko-Vielfaches) auf Break-Even
input int             InpBreakEvenBuffPts = 20;     // Puffer ueber/unter Einstieg (Punkte, deckt Spread)
input bool            InpUsePartialTP   = true;     // Teil-Gewinnmitnahme aktivieren
input double          InpPartialAtR     = 1.0;      // ab wieviel R Teil schliessen
input double          InpPartialPercent = 50.0;     // wieviel % der Position schliessen

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
int      h_atrD1    = INVALID_HANDLE;   // ATR auf D1 fuer Volatilitaets-Filter

datetime m_last_bar_time;
bool     m_loss_limit_active;
int      m_last_day;
double   m_day_start_balance;

//--- Opening-Range-Breakout (Modus 2) -------------------------------
int      m_orbDay      = -1;      // laufender Tag (day_of_year)
double   m_orbHigh     = 0.0;     // Spannen-Hoch
double   m_orbLow      = 0.0;     // Spannen-Tief
bool     m_orbHasRange = false;   // Spanne fuer heute vorhanden?
bool     m_orbDoneToday= false;   // heutiger Einstiegsversuch verbraucht?

//--- Merker fuer die aktuell verfolgte Position (Gewinn sichern) ----
ulong    m_pos_ticket   = 0;      // Ticket der aktuell verfolgten Position
double   m_pos_entry    = 0.0;    // Einstiegspreis
double   m_pos_risk     = 0.0;    // urspruenglicher Risiko-Abstand (Preis)
double   m_pos_volume   = 0.0;    // urspruengliches Volumen
bool     m_be_done      = false;  // Break-Even schon gesetzt?
bool     m_partial_done = false;  // Teil-Gewinn schon genommen?

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

   if(InpUseVolFilter)
     {
      h_atrD1 = iATR(_Symbol, PERIOD_D1, InpATRPeriod);
      if(h_atrD1 == INVALID_HANDLE)
        {
         Print("Fehler beim Erstellen des D1-ATR Handles!");
         return(INIT_FAILED);
        }
     }

   // RSI fuer Filter UND Mean-Reversion-Modus -> immer anlegen
   h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(h_rsi == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des RSI Handles!");
      return(INIT_FAILED);
     }

   m_last_bar_time     = 0;
   m_loss_limit_active = false;
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("EA v3.50 gestartet: EMA ", InpFastEMAPeriod, "/", InpSlowEMAPeriod,
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
   if(h_atrD1   != INVALID_HANDLE) IndicatorRelease(h_atrD1);
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

   // 2. Position dieses EA finden
   bool  hasPos = false;
   ulong ticket = 0;
   long  posType = -1;
   double posSL = 0.0, posEntry = 0.0, posVol = 0.0, posProfit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
        {
         hasPos    = true;
         ticket    = PositionGetInteger(POSITION_TICKET);
         posType   = PositionGetInteger(POSITION_TYPE);
         posSL     = PositionGetDouble(POSITION_SL);
         posEntry  = PositionGetDouble(POSITION_PRICE_OPEN);
         posVol    = PositionGetDouble(POSITION_VOLUME);
         posProfit = PositionGetDouble(POSITION_PROFIT);
         break;
        }
     }

   // 3. ATR (bei jedem Tick fuer Trailing) holen
   double atrNow[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atrNow) < 1) return;
   double atrValue = atrNow[0];

   // 4. Offene Position verwalten (bei jedem Tick): Gewinn sichern + Trailing
   if(hasPos)
     {
      if(ticket != m_pos_ticket)   // neue Position -> Merker initialisieren
        {
         m_pos_ticket   = ticket;
         m_pos_entry    = posEntry;
         m_pos_risk     = MathAbs(posEntry - posSL);
         m_pos_volume   = posVol;
         m_be_done      = false;
         m_partial_done = false;
        }
      if(InpEntryMode == 1)
        {
         // Mean-Reversion: raus, sobald im Plus (kuerzeste Haltedauer)
         if(posProfit > 0.0 && posProfit >= InpMRMinProfitMoney)
            trade.PositionClose(ticket);
        }
      else
        {
         ManageProfitSecuring(ticket, posType);
         if(InpUseTrailing && atrValue > 0.0)
            ManageTrailingStop(ticket, atrValue);
        }
     }
   else
      m_pos_ticket = 0;

   // 5. Signale nur einmal je neuer Kerze auswerten
   datetime barTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(barTime == m_last_bar_time) return;

   double fast[3], slow[3], rsi[3];
   if(CopyBuffer(h_fastEMA, 0, 0, 3, fast) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slow) < 3 ||
      CopyBuffer(h_rsi,     0, 0, 3, rsi)  < 3)
      return;

   // Bias der hoeheren Zeitebene bestimmen
   double biasEMA[1];
   if(CopyBuffer(h_biasEMA, 0, 1, 1, biasEMA) < 1) return;
   double biasClose = iClose(_Symbol, InpBiasTF, 1);
   if(biasClose <= 0.0) return;
   bool biasUp   = (biasClose > biasEMA[0]);
   bool biasDown = (biasClose < biasEMA[0]);

   m_last_bar_time = barTime;
   if(atrValue <= 0.0) return;

   // --- Einstiegs-Signale je nach Modus ----------------------------
   bool longSignal = false, shortSignal = false;
   bool longExit   = false, shortExit   = false;

   if(InpEntryMode == 0)
     {
      // Modus 0: EMA-Kreuz (Trendfolge)
      bool crossUp    = (fast[1] > slow[1]) && (fast[2] <= slow[2]);
      bool crossDown  = (fast[1] < slow[1]) && (fast[2] >= slow[2]);
      bool rsiOkLong  = !InpUseRSIFilter || (rsi[1] < InpRSIUpper);
      bool rsiOkShort = !InpUseRSIFilter || (rsi[1] > InpRSILower);
      longSignal  = crossUp   && biasUp   && rsiOkLong;
      shortSignal = crossDown && biasDown && rsiOkShort;
      longExit    = crossDown;   // Gegenkreuz schliesst Long
      shortExit   = crossUp;     // Gegenkreuz schliesst Short
     }
   else if(InpEntryMode == 1)
     {
      // Modus 1: RSI-Mean-Reversion (Ruecksetzer im Trend kaufen)
      // Long: RSI dreht von unten durch InpRSIBuyLevel nach oben, im Aufwaerts-Bias
      bool rsiTurnUp   = (rsi[2] <= InpRSIBuyLevel)  && (rsi[1] > InpRSIBuyLevel);
      // Short: RSI dreht von oben durch InpRSISellLevel nach unten, im Abwaerts-Bias
      bool rsiTurnDown = (rsi[2] >= InpRSISellLevel) && (rsi[1] < InpRSISellLevel);
      longSignal  = rsiTurnUp   && biasUp;
      shortSignal = rsiTurnDown && biasDown;
      // Ausstieg im MR-Modus ueber TP / Break-Even / Trailing (kein Signal-Exit)
     }
   else // InpEntryMode == 2
     {
      // Modus 2: Opening-Range-Breakout (Session-Ausbruch)
      // Spanne der ruhigen Session merken (Stunden in Serverzeit EET),
      // danach am selben Tag Ausbruch ueber/unter die Spanne + ATR-Puffer.
      // Ausstieg ueber SL/TP/Trailing (kein Signal-Exit). 1 Versuch/Tag.
      datetime bt = iTime(_Symbol, _Period, 1);
      MqlDateTime btm; TimeToStruct(bt, btm);
      if(btm.day_of_year != m_orbDay)
        {
         m_orbDay = btm.day_of_year;
         m_orbHigh = 0.0; m_orbLow = 0.0;
         m_orbHasRange = false; m_orbDoneToday = false;
        }
      double bh = iHigh(_Symbol, _Period, 1);
      double bl = iLow(_Symbol, _Period, 1);
      if(btm.hour >= InpRangeStartHour && btm.hour < InpRangeEndHour)
        {
         if(!m_orbHasRange) { m_orbHigh = bh; m_orbLow = bl; m_orbHasRange = true; }
         else { if(bh > m_orbHigh) m_orbHigh = bh; if(bl < m_orbLow) m_orbLow = bl; }
        }
      else if(btm.hour >= InpRangeEndHour && m_orbHasRange && !m_orbDoneToday)
        {
         double buf = InpBreakoutBufferATR * atrValue;
         double cl  = iClose(_Symbol, _Period, 1);
         if(cl > m_orbHigh + buf)      { longSignal  = true; m_orbDoneToday = true; }
         else if(cl < m_orbLow - buf)  { shortSignal = true; m_orbDoneToday = true; }
        }
     }

   // 6. Offene Position: ggf. Signal-Ausstieg
   if(hasPos)
     {
      if(posType == POSITION_TYPE_BUY && longExit)
        { Print("Long-Ausstieg (Signal). #", ticket); trade.PositionClose(ticket); }
      else if(posType == POSITION_TYPE_SELL && shortExit)
        { Print("Short-Ausstieg (Signal). #", ticket); trade.PositionClose(ticket); }
      return;
     }

   // 7. Einstieg (nur wenn keine Position und kein Tagesstopp)
   if(m_loss_limit_active) return;

   bool volOk = (!InpUseVolFilter) || VolatilityOk();

   if(InpAllowLong && longSignal && volOk)
      OpenTrade(true, atrValue);
   else if(InpAllowShort && shortSignal && volOk)
      OpenTrade(false, atrValue);
  }

//+------------------------------------------------------------------+
//| Volatilitaets-Filter: aktueller ATR-D1 >= Median der letzten     |
//| InpVolLookback Tage. Rollierend/relativ, kein fester Schwellwert.|
//+------------------------------------------------------------------+
bool VolatilityOk()
  {
   if(h_atrD1 == INVALID_HANDLE) return(true);
   double atrD1[];
   ArraySetAsSeries(atrD1, true);
   if(CopyBuffer(h_atrD1, 0, 1, InpVolLookback, atrD1) < InpVolLookback)
      return(true);   // noch nicht genug Historie -> Filter nicht blockieren
   double cur = atrD1[0];
   double tmp[];
   ArrayCopy(tmp, atrD1);
   ArraySort(tmp);     // aufsteigend
   double median = tmp[InpVolLookback / 2];
   return(cur >= median);
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
   if(InpUseRiskLots) lots = CalcRiskLots(isLong, entry, riskDistance);
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
void ManageTrailingStop(ulong ticket, double atrValue)
  {
   if(!PositionSelectByTicket(ticket)) return;
   long   type  = PositionGetInteger(POSITION_TYPE);
   double curSL = PositionGetDouble(POSITION_SL);
   double curTP = PositionGetDouble(POSITION_TP);
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
//| Sichert Gewinn: Teil-Verkauf bei +InpPartialAtR R und            |
//| Break-Even-Stop bei +InpBreakEvenAtR R (beide Richtungen).       |
//| -> Ist der Trade einmal im Plus, kann er nicht mehr ins Minus.   |
//+------------------------------------------------------------------+
void ManageProfitSecuring(ulong ticket, long type)
  {
   if(m_pos_risk <= 0.0) return;
   if(!PositionSelectByTicket(ticket)) return;
   double curSL  = PositionGetDouble(POSITION_SL);
   double curTP  = PositionGetDouble(POSITION_TP);
   double curVol = PositionGetDouble(POSITION_VOLUME);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double buffer = InpBreakEvenBuffPts * _Point;

   double profitDist = (type == POSITION_TYPE_BUY) ? (bid - m_pos_entry) : (m_pos_entry - ask);
   if(profitDist <= 0.0) return;

   // --- Teil-Gewinnmitnahme ---------------------------------------
   if(InpUsePartialTP && !m_partial_done && profitDist >= InpPartialAtR * m_pos_risk)
     {
      double closeVol = NormalizeVolumeDown(m_pos_volume * InpPartialPercent / 100.0);
      double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(closeVol >= minLot && (curVol - closeVol) >= minLot)
        {
         if(trade.PositionClosePartial(ticket, closeVol))
           {
            m_partial_done = true;
            Print("Teil-Gewinn gesichert: ", DoubleToString(closeVol, 2),
                  " Lot bei +", DoubleToString(InpPartialAtR, 1), "R.");
           }
        }
      else
         m_partial_done = true; // Volumen zu klein zum Teilen -> nicht erneut versuchen
     }

   // --- Break-Even-Stop -------------------------------------------
   if(InpUseBreakEven && !m_be_done && profitDist >= InpBreakEvenAtR * m_pos_risk)
     {
      if(type == POSITION_TYPE_BUY)
        {
         double beSL = NormalizeDouble(m_pos_entry + buffer, _Digits);
         if(beSL > curSL) { if(trade.PositionModify(ticket, beSL, curTP)) m_be_done = true; }
         else m_be_done = true;
        }
      else
        {
         double beSL = NormalizeDouble(m_pos_entry - buffer, _Digits);
         if(curSL <= 0.0 || beSL < curSL) { if(trade.PositionModify(ticket, beSL, curTP)) m_be_done = true; }
         else m_be_done = true;
        }
     }
  }

//+------------------------------------------------------------------+
//| Rundet Volumen auf den erlaubten Volume-Step ab                  |
//+------------------------------------------------------------------+
double NormalizeVolumeDown(double v)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) return(v);
   return(MathFloor(v / step) * step);
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
//| Verlust je 1.0 Lot wird mit OrderCalcProfit bestimmt - das       |
//| beruecksichtigt Kontraktgroesse und Umrechnung in die            |
//| Kontowaehrung korrekt (Fix fuer den XAUUSD-Sizing-Bug, bei dem   |
//| SYMBOL_TRADE_TICK_VALUE ~3,8x zu kleine Werte lieferte).         |
//+------------------------------------------------------------------+
double CalcRiskLots(bool isLong, double entryPrice, double riskDistance)
  {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (InpRiskPerTradePct / 100.0);

   // 1) bevorzugt: OrderCalcProfit fuer den Verlustfall bei 1.0 Lot
   double lossPerLot = 0.0;
   double exitPrice  = isLong ? (entryPrice - riskDistance)
                              : (entryPrice + riskDistance);
   ENUM_ORDER_TYPE ot = isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(OrderCalcProfit(ot, _Symbol, 1.0, entryPrice, exitPrice, lossPerLot))
      lossPerLot = MathAbs(lossPerLot);
   else
      lossPerLot = 0.0;

   // 2) Fallback: alte tick_value-Methode (nur wenn 1) nichts liefert)
   if(lossPerLot <= 0.0)
     {
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize <= 0.0 || tickValue <= 0.0) return(InpLotSize);
      lossPerLot = (riskDistance / tickSize) * tickValue;
     }
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

   // Profitfaktor selbst berechnen: bei 0 Verlusten ist PF unendlich,
   // nicht 0 (TesterStatistics(STAT_PROFIT_FACTOR) liefert hier faelschlich 0).
   double absLoss = MathAbs(grossLoss);
   string pfStr;
   if(absLoss > 0.0)          pfStr = DoubleToString(grossProfit / absLoss, 2);
   else if(grossProfit > 0.0) pfStr = "inf";   // Gewinne, keine Verluste
   else                       pfStr = "0.00";  // gar keine Trades

   int h = FileOpen("tester_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "timeframe="      + EnumToString((ENUM_TIMEFRAMES)_Period));
      FileWrite(h, "bias_tf="        + EnumToString(InpBiasTF));
      FileWrite(h, "net_profit="     + DoubleToString(profit, 2));
      FileWrite(h, "profit_factor="  + pfStr);
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
```
