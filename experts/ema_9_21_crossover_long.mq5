//+------------------------------------------------------------------+
//| EMA 9/21 Crossover (Long only) mit Tagesverlust-Stopp            |
//|                                                                  |
//| Idee (fuer EURUSD, H4 gedacht):                                  |
//|  - Kauf: schnelle EMA (Standard 9) kreuzt die langsame EMA       |
//|    (Standard 21) von unten nach oben ("goldenes Kreuz").         |
//|  - Ausstieg: schnelle EMA kreuzt wieder nach unten, ODER der     |
//|    schwebende Gewinn/Verlust der Position erreicht +TP% / -SL%   |
//|    vom Kapital.                                                  |
//|  - Schutz: ueberschreitet der Tagesverlust MaxDailyLossPercent,  |
//|    schliesst der EA die Position und pausiert bis zum naechsten  |
//|    Handelstag.                                                   |
//|                                                                  |
//| Nur fuer Demo-/Paper-Trading gedacht. Kompilieren (F7) und der   |
//| Strategy Tester laufen im MetaEditor/MT5 beim Nutzer.            |
//+------------------------------------------------------------------+
#property copyright "Phase 1 - Demo/Paper"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

//--- Eingaben: Indikatoren ------------------------------------------
input int    InpFastEMA            = 9;      // Schnelle EMA (Perioden)
input int    InpSlowEMA            = 21;     // Langsame EMA (Perioden)

//--- Eingaben: Risiko / Ausstieg ------------------------------------
input double InpStopLossPercent    = 2.0;    // Stop-Loss (% vom Kapital)
input double InpTakeProfitPercent  = 4.0;    // Take-Profit (% vom Kapital)
input double InpMaxDailyLossPercent= 5.0;    // Tagesverlust-Limit (% vom Kapital)

//--- Eingaben: Position ---------------------------------------------
input double InpLotSize            = 0.10;   // Feste Lotgroesse
input ulong  InpMagic              = 990021; // Magic-Nummer (kennzeichnet EA-Trades)

//--- globale Variablen ----------------------------------------------
CTrade   g_trade;                 // Handelsobjekt von MetaQuotes
int      g_handleFast = INVALID_HANDLE; // Indikator-Handle schnelle EMA
int      g_handleSlow = INVALID_HANDLE; // Indikator-Handle langsame EMA
datetime g_lastBarTime = 0;       // Zeit der zuletzt verarbeiteten Kerze
double   g_entryBalance = 0.0;    // Kontostand beim Einstieg (fuer SL/TP in Geld)
int      g_currentDay = -1;       // laufender Handelstag (Tag im Monat)
double   g_dayStartEquity = 0.0;  // Equity zu Tagesbeginn (fuer Tagesverlust)
bool     g_dailyStopHit = false;  // true = heute wegen Verlustlimit pausiert

//+------------------------------------------------------------------+
//| Initialisierung                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastEMA >= InpSlowEMA)
     {
      Print("Fehler: Schnelle EMA muss kleiner sein als langsame EMA.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   g_handleFast = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_handleSlow = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleFast == INVALID_HANDLE || g_handleSlow == INVALID_HANDLE)
     {
      Print("Fehler: EMA-Indikator konnte nicht erstellt werden.");
      return(INIT_FAILED);
     }

   g_trade.SetExpertMagicNumber(InpMagic);

   // Tages-Startwerte setzen
   ResetDay();

   Print("EA gestartet: EMA ", InpFastEMA, "/", InpSlowEMA,
         ", SL ", InpStopLossPercent, "%, TP ", InpTakeProfitPercent,
         "%, Tageslimit ", InpMaxDailyLossPercent, "%");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Aufraeumen                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_handleFast != INVALID_HANDLE) IndicatorRelease(g_handleFast);
   if(g_handleSlow != INVALID_HANDLE) IndicatorRelease(g_handleSlow);
  }

//+------------------------------------------------------------------+
//| Setzt die Tages-Startwerte (Equity, Datum, Pause-Flag) neu       |
//+------------------------------------------------------------------+
void ResetDay()
  {
   MqlDateTime jetzt;
   TimeToStruct(TimeCurrent(), jetzt);
   g_currentDay      = jetzt.day;
   g_dayStartEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   g_dailyStopHit    = false;
  }

//+------------------------------------------------------------------+
//| Zaehlt offene Positionen dieses EA (Magic + Symbol)              |
//+------------------------------------------------------------------+
int CountMyPositions()
  {
   int anzahl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == (long)InpMagic &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         anzahl++;
     }
   return(anzahl);
  }

//+------------------------------------------------------------------+
//| Schliesst alle Positionen dieses EA (Magic + Symbol)            |
//+------------------------------------------------------------------+
void CloseMyPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == (long)InpMagic &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         g_trade.PositionClose(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Summe des schwebenden Gewinns/Verlusts dieses EA (in Geld)       |
//+------------------------------------------------------------------+
double MyFloatingProfit()
  {
   double summe = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == (long)InpMagic &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         summe += PositionGetDouble(POSITION_PROFIT);
     }
   return(summe);
  }

//+------------------------------------------------------------------+
//| Haupt-Tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   // --- Tageswechsel erkennen (Serverzeit) ---------------------------
   MqlDateTime jetzt;
   TimeToStruct(TimeCurrent(), jetzt);
   if(jetzt.day != g_currentDay)
      ResetDay();

   // --- 1) Tagesverlust-Stopp pruefen (bei jedem Tick) --------------
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(g_dayStartEquity > 0.0)
     {
      double tagesverlustProzent = (g_dayStartEquity - equity) / g_dayStartEquity * 100.0;
      if(!g_dailyStopHit && tagesverlustProzent >= InpMaxDailyLossPercent)
        {
         if(CountMyPositions() > 0)
            CloseMyPositions();
         g_dailyStopHit = true;
         Print("Tagesverlust-Limit erreicht (", DoubleToString(tagesverlustProzent, 2),
               "%). Handel bis morgen pausiert.");
        }
     }

   // --- 2) SL/TP in % vom Kapital pruefen (bei jedem Tick) ----------
   if(CountMyPositions() > 0 && g_entryBalance > 0.0)
     {
      double floating   = MyFloatingProfit();
      double verlustGeld = g_entryBalance * InpStopLossPercent   / 100.0; // z.B. 2 %
      double gewinnGeld  = g_entryBalance * InpTakeProfitPercent / 100.0; // z.B. 4 %

      if(floating <= -verlustGeld)
        {
         CloseMyPositions();
         Print("Stop-Loss (", InpStopLossPercent, "% vom Kapital) ausgeloest.");
        }
      else if(floating >= gewinnGeld)
        {
         CloseMyPositions();
         Print("Take-Profit (", InpTakeProfitPercent, "% vom Kapital) ausgeloest.");
        }
     }

   // --- 3) Signale nur einmal je abgeschlossener Kerze auswerten ----
   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime == g_lastBarTime)
      return;            // noch dieselbe Kerze -> nichts weiter tun
   g_lastBarTime = barTime;

   // EMA-Werte der beiden zuletzt abgeschlossenen Kerzen holen
   double fast[2], slow[2];
   if(CopyBuffer(g_handleFast, 0, 1, 2, fast) < 2) return;
   if(CopyBuffer(g_handleSlow, 0, 1, 2, slow) < 2) return;
   // Index 0 = vorletzte Kerze, Index 1 = letzte abgeschlossene Kerze
   double fastVorher = fast[0], fastJetzt = fast[1];
   double slowVorher = slow[0], slowJetzt = slow[1];

   bool kreuzHoch = (fastVorher <= slowVorher) && (fastJetzt > slowJetzt); // Kaufsignal
   bool kreuzTief = (fastVorher >= slowVorher) && (fastJetzt < slowJetzt); // Ausstiegssignal

   // --- 4) Ausstieg beim Gegenkreuz --------------------------------
   if(kreuzTief && CountMyPositions() > 0)
     {
      CloseMyPositions();
      Print("Ausstieg: EMA-Kreuz nach unten.");
      return;
     }

   // --- 5) Einstieg (nur Long) -------------------------------------
   //     Bedingungen: Kaufsignal, keine offene Position, kein Tagesstopp
   if(kreuzHoch && CountMyPositions() == 0 && !g_dailyStopHit)
     {
      if(g_trade.Buy(InpLotSize, _Symbol))
        {
         g_entryBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         Print("Einstieg Long: ", DoubleToString(InpLotSize, 2), " Lot ", _Symbol);
        }
      else
        {
         Print("Kauf fehlgeschlagen, Fehlercode: ", g_trade.ResultRetcode());
        }
     }
  }
//+------------------------------------------------------------------+
