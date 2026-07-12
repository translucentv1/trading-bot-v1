//+------------------------------------------------------------------+
//| EMA 9/21 Crossover (Long only) mit Trendfilter EMA 200          |
//|                                                                  |
//| Neu in v1.10 (Phase 2):                                         |
//|  - Optionaler Trendfilter (EMA 200): Kauf nur, wenn EMA 9       |
//|    ueber EMA 200 liegt (Aufwaertstrend bestaetigt).             |
//|  - Echter SL/TP-Preis wird direkt in der Buy-Order gesetzt.     |
//|  - Slippage als Input-Parameter.                                |
//|                                                                  |
//| Nur fuer Demo-/Paper-Trading gedacht. Kompilieren (F7) und der  |
//| Strategy Tester laufen im MetaEditor/MT5 beim Nutzer.           |
//+------------------------------------------------------------------+
#property copyright "Phase 2 - Demo/Paper"
#property version   "1.10"
#property strict
#property description "EMA-9/21-Crossover Long-Only Expert Advisor"
#property description "Mit integriertem Tagesverlust-Stopp und SL/TP in % vom Kapital."

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Indikatoren ------------------------------------------
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = 9;       // Perioden schnelle EMA (Standard: 9)
input int      InpSlowEMAPeriod  = 21;      // Perioden langsame EMA (Standard: 21)

//--- Eingaben: Trendfilter ------------------------------------------
input group "--- Trend-Filter ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)

//--- Eingaben: Risikomanagement ------------------------------------
input group "--- Risikomanagement ---"
input double   InpLotSize        = 0.1;     // Handelsvolumen (Lots)
input double   InpStopLossPct    = 2.0;     // Stop-Loss in % vom Kontostand
input double   InpTakeProfitPct  = 4.0;     // Take-Profit in % vom Kontostand
input double   InpDailyLossLimit = 5.0;     // Tagesverlust-Limit in % vom Kontostand

//--- Eingaben: System ----------------------------------------------
input group "--- System Einstellungen ---"
input ulong    InpMagicNumber    = 123456;  // Magic Number fuer Identifikation
input int      InpSlippage       = 3;       // Maximaler Slippage (Pips)

//--- Globale Variablen ---------------------------------------------
int      h_fastEMA;           // Handle fuer schnelle EMA
int      h_slowEMA;           // Handle fuer langsame EMA
int      h_trendEMA;          // Handle fuer Trend-Filter EMA
datetime m_last_bar_time;     // Zeit der zuletzt verarbeiteten Kerze
bool     m_loss_limit_active; // true = Tages-Verlustlimit erreicht, kein Handel
int      m_last_day;          // Tag des Jahres (fuer Tageswechsel-Erkennung)
double   m_day_start_balance; // Kontostand am Tagesbeginn

//+------------------------------------------------------------------+
//| Initialisierung                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

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

   m_last_bar_time     = 0;
   m_loss_limit_active = false;

   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("EA gestartet: EMA ", InpFastEMAPeriod, "/", InpSlowEMAPeriod,
         ", Trendfilter EMA ", InpTrendEMAPeriod, " (", (InpUseTrendFilter ? "aktiv" : "deaktiviert"), ")",
         ", SL ", InpStopLossPct, "%, TP ", InpTakeProfitPct, "%",
         ", Tageslimit ", InpDailyLossLimit, "%");
   Print("Tages-Startguthaben: ", DoubleToString(m_day_start_balance, 2));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Aufraeumen                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(h_fastEMA);
   IndicatorRelease(h_slowEMA);
   if(h_trendEMA != INVALID_HANDLE)
      IndicatorRelease(h_trendEMA);
   Print("EA deinitialisiert. Grund-Code: ", reason);
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

   // 2. Tagesverlust-Limit pruefen
   if(CheckDailyLossLimit())
     {
      if(!m_loss_limit_active)
        {
         m_loss_limit_active = true;
         Print("WARNUNG: Tagesverlust-Limit ueberschritten! Alle Positionen werden geschlossen.");
         CloseAllPositions();
        }
      return;
     }

   // 3. Nur einmal pro neuer (abgeschlossener) Kerze handeln
   datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(current_bar_time == m_last_bar_time)
      return;

   // 4. EMA-Werte abrufen (3 Kerzen: Index 0 = laufende, 1 = letzte, 2 = vorletzte)
   double fastEMA[3], slowEMA[3], trendEMA[3];
   if(CopyBuffer(h_fastEMA, 0, 0, 3, fastEMA) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slowEMA) < 3)
     {
      Print("Fehler beim Kopieren der EMA-Werte!");
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

   // Jetzt Bar-Zeit merken (nach erfolgreichem Datenabruf)
   m_last_bar_time = current_bar_time;

   // 5. Signale berechnen
   // Golden Cross: schnelle EMA kreuzt langsame EMA nach oben
   bool isGoldenCross = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   // Death Cross: schnelle EMA kreuzt langsame EMA nach unten (Ausstieg)
   bool isDeathCross  = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   // Trendfilter: Kauf nur im Aufwaertstrend (EMA 9 ueber EMA 200)
   bool isTrendUp = true;
   if(InpUseTrendFilter && h_trendEMA != INVALID_HANDLE)
      isTrendUp = (fastEMA[1] > trendEMA[1]);

   // 6. Offene Position dieses EA suchen
   bool hasOpenPosition = false;
   ulong ticket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         hasOpenPosition = true;
         ticket = PositionGetInteger(POSITION_TICKET);
         break;
        }
     }

   // 7. Handelslogik
   if(hasOpenPosition)
     {
      // Ausstieg beim Gegenkreuz (Death Cross)
      if(isDeathCross)
        {
         Print("Ausstiegssignal: EMA-Kreuzung nach unten. Schliesse Position #", ticket);
         trade.PositionClose(ticket);
        }
     }
   else
     {
      // Einstieg beim Golden Cross - nur wenn Trend aufwaerts und kein Tagesstopp
      if(isGoldenCross && isTrendUp && !m_loss_limit_active)
         OpenLongPosition();
     }
  }

//+------------------------------------------------------------------+
//| Prueft ob Tagesverlust-Limit erreicht ist                        |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
  {
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double daily_pnl      = current_equity - m_day_start_balance;
   if(daily_pnl < 0)
     {
      double loss_percent = (MathAbs(daily_pnl) / m_day_start_balance) * 100.0;
      if(loss_percent >= InpDailyLossLimit)
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
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         Print("Schliesse Position #", ticket, " (Tagesverlust-Stopp).");
         trade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//| Oeffnet eine Long-Position mit berechnetem SL und TP            |
//+------------------------------------------------------------------+
void OpenLongPosition()
  {
   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double risk_amount   = balance * (InpStopLossPct  / 100.0);
   double profit_amount = balance * (InpTakeProfitPct / 100.0);

   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tick_size <= 0 || tick_value <= 0)
     {
      Print("Fehler: Tick-Groesse oder Tick-Wert ungueltig!");
      return;
     }

   // SL/TP-Abstand in Kurs-Punkten berechnen
   double sl_distance = (risk_amount   / (InpLotSize * tick_value)) * tick_size;
   double tp_distance = (profit_amount / (InpLotSize * tick_value)) * tick_size;

   double sl_price = NormalizeDouble(ask - sl_distance, _Digits);
   double tp_price = NormalizeDouble(ask + tp_distance, _Digits);

   Print("Kaufsignal (Golden Cross", (InpUseTrendFilter ? " + Trendfilter" : ""), ")");
   Print("Lots: ", DoubleToString(InpLotSize, 2),
         " | Ask: ", DoubleToString(ask, _Digits),
         " | SL: ", DoubleToString(sl_price, _Digits), " (Risiko: ", DoubleToString(risk_amount, 2), ")",
         " | TP: ", DoubleToString(tp_price, _Digits), " (Ziel: ", DoubleToString(profit_amount, 2), ")");

   if(!trade.Buy(InpLotSize, _Symbol, ask, sl_price, tp_price, "EMA Crossover Long"))
      Print("Kauf fehlgeschlagen! Code: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   else
      Print("Kauf ausgefuehrt. Ticket: ", trade.ResultOrder());
  }
//+------------------------------------------------------------------+
