//+------------------------------------------------------------------+
//|                                    ema_9_21_crossover_long.mq5   |
//|                                Philipp Behnisch / Trading Studio |
//|                                             https://ai.studio/   |
//+------------------------------------------------------------------+
#property copyright "Philipp Behnisch / Trading Studio"
#property link      "https://ai.studio/"
#property version   "1.00"
#property description "EMA-9/21-Crossover Long-Only Expert Advisor"
#property description "Mit integriertem Tagesverlust-Stopp und SL/TP in % vom Kapital."

// Trade-Bibliothek importieren
#include <Trade\Trade.mqh>
CTrade trade;

//--- Input Parameter
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = 9;       // Perioden schnelle EMA (Standard: 9)
input int      InpSlowEMAPeriod  = 21;      // Perioden langsame EMA (Standard: 21)

input group "--- Trend-Filter ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)

input group "--- Risikomanagement ---"
input double   InpLotSize        = 0.1;     // Handelsvolumen (Lots)
input double   InpStopLossPct    = 2.0;     // Stop-Loss in % vom Kontostand
input double   InpTakeProfitPct  = 4.0;     // Take-Profit in % vom Kontostand
input double   InpDailyLossLimit = 5.0;     // Tagesverlust-Limit in % vom Kontostand

input group "--- System Einstellungen ---"
input ulong    InpMagicNumber    = 123456;  // Magic Number fuer Identifikation
input int      InpSlippage       = 3;       // Maximaler Slippage (Pips)

//--- Globale Variablen
int      h_fastEMA;           // Handle fuer schnelle EMA
int      h_slowEMA;           // Handle fuer langsame EMA
int      h_trendEMA;          // Handle fuer Trend-Filter EMA
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

   // EMA Handles initialisieren
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

   // Trend EMA Handle initialisieren
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

   Print("EA erfolgreich initialisiert.");
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
   if(h_trendEMA != INVALID_HANDLE)
     {
      IndicatorRelease(h_trendEMA);
     }
   Print("EA deinitialisiert. Grund-Code: ", reason);
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

   // 3. Auf neue Kerze pruefen (EMA-Crossover wird fuer Stabilitaet auf Schlusskursen berechnet)
   datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(current_bar_time == m_last_bar_time)
     {
      return; // Wir berechnen nur einmal pro neuer Kerze
     }

   // 4. EMA Werte abfragen
   double fastEMA[3];
   double slowEMA[3];
   double trendEMA[3];

   // Werte kopieren (Index 0 = aktuelle unvollstaendige Kerze, Index 1 = letzte geschlossene, Index 2 = vorletzte)
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

   // Wenn wir erfolgreich die Werte kopiert haben, merken wir uns die Bar-Zeit
   m_last_bar_time = current_bar_time;

   // 5. Signalpruefung (Long-Only)
   // Schnelle EMA kreuzt Langsame EMA nach oben auf den letzten geschlossenen Kerzen
   // Kerze 1: fast > slow AND Kerze 2: fast <= slow
   bool isGoldenCross = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   
   // Schnelle EMA kreuzt Langsame EMA nach unten (Ausstiegssignal)
   bool isDeathCross  = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   // Trend-Bedingung: Nur kaufen, wenn die schnelle EMA ueber der Trend-EMA liegt (Aufwaertstrend)
   bool isTrendUp = true;
   if(InpUseTrendFilter && h_trendEMA != INVALID_HANDLE)
     {
      isTrendUp = (fastEMA[1] > trendEMA[1]);
     }

   // Pruefen, ob wir bereits eine offene Position haben (mit Magic Number)
   bool hasOpenPosition = False;
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

   // 6. Trading Logik ausfuehren
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
      // Wenn wir ein Einstiegssignal (Golden Cross) erhalten, der Trend aufwaerts zeigt und kein Tagesverlust-Limit aktiv ist
      if(isGoldenCross && isTrendUp && !m_loss_limit_active)
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
   
   // Verlust wird als Differenz zum morgendlichen Kontostand berechnet
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
//| Oeffnet eine neue Long-Position mit berechnetem SL und TP        |
//+------------------------------------------------------------------+
void OpenLongPosition()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   // SL und TP in Geldbetrag berechnen
   double risk_amount = balance * (InpStopLossPct / 100.0);
   double profit_amount = balance * (InpTakeProfitPct / 100.0);
   
   // Pip-Wert und Punkt-Berechnung
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tick_size <= 0 || tick_value <= 0)
     {
      Print("Fehler bei Symbol-Informationen (Tick-Groesse oder Tick-Wert)!");
      return;
     }
     
   // Berechne Distanz fuer SL und TP in Kurs-Punkten basierend auf dem Risiko-Geldwert
   // Formel: Preis_Diff = (Geldwert / (Lots * Tick_Wert)) * Tick_Groesse
   double sl_distance = (risk_amount / (InpLotSize * tick_value)) * tick_size;
   double tp_distance = (profit_amount / (InpLotSize * tick_value)) * tick_size;
   
   // SL & TP absolute Preise berechnen
   double sl_price = NormalizeDouble(ask - sl_distance, _Digits);
   double tp_price = NormalizeDouble(ask + tp_distance, _Digits);
   
   Print("Kaufe ", DoubleToString(InpLotSize, 2), " Lots bei ", DoubleToString(ask, _Digits));
   Print("SL Preis: ", DoubleToString(sl_price, _Digits), " (Risiko: ", DoubleToString(risk_amount, 2), " EUR)");
   Print("TP Preis: ", DoubleToString(tp_price, _Digits), " (Ziel: ", DoubleToString(profit_amount, 2), " EUR)");

   // Kauf ausfuehren
   if(!trade.Buy(InpLotSize, _Symbol, ask, sl_price, tp_price, "EMA Crossover Long"))
     {
      Print("Kauf-Order fehlgeschlagen! Fehlercode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Kauf-Order erfolgreich ausgefuehrt. Ticket: ", trade.ResultOrder());
     }
  }
//+------------------------------------------------------------------+
