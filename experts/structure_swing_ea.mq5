//+------------------------------------------------------------------+
//| structure_swing_ea.mq5 - Marktstruktur (Swing High/Low) Trend-EA |
//|                                                                  |
//| Idee (strukturbasiert, KEIN Indikator):                         |
//|  - Auf einer Filter-Zeitebene (hoeherer Trend) und einer Signal-|
//|    Zeitebene werden objektive Swing-Hochs/-Tiefs per Fractal     |
//|    erkannt (Depth = N Kerzen links UND rechts). Ein Swing gilt   |
//|    erst als bestaetigt, wenn N Kerzen rechts geschlossen sind -> |
//|    danach wird er NIE mehr veraendert (kein Repaint).            |
//|  - Filter-Trend: x aufeinanderfolgende hoehere Hochs UND hoehere |
//|    Tiefs = Aufwaerts; x tiefere Hochs UND Tiefs = Abwaerts.      |
//|    Trend bricht, wenn der Schlusskurs unter das letzte Swing-Tief|
//|    (Auf) bzw. ueber das letzte Swing-Hoch (Ab) faellt.           |
//|  - Einstieg: nur bei aktivem Filter-Trend UND y gleichgerichtete |
//|    Swings auf der Signal-Zeitebene. Bis zu InpMaxTradesPerTrend  |
//|    Einstiege pro Filter-Trend.                                   |
//|  - Ausstieg: alle Long schliessen, wenn der Auf-Trend bricht;    |
//|    alle Short, wenn der Ab-Trend bricht.                         |
//|  - Risiko dynamisch: Lot so, dass ein SL-Treffer InpRiskMoney    |
//|    kostet. SL/TP in Punkten oder % vom Einstieg, TP optional,    |
//|    SL optional am letzten Swing-Punkt.                           |
//|                                                                  |
//| Nur fuer Demo-/Paper-Trading. Arbeitet auf dem aktuellen         |
//| Chart-Symbol, unabhaengig von der Chart-Zeitebene.               |
//+------------------------------------------------------------------+
#property copyright "Struktur-Swing-EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//--- Eingaben: Zeitebenen & Struktur --------------------------------
input group "--- Zeitebenen & Struktur ---"
input ENUM_TIMEFRAMES InpSignalTF     = PERIOD_H1;  // Signal-Zeitebene
input ENUM_TIMEFRAMES InpFilterTF     = PERIOD_H4;  // Filter-Zeitebene (hoeherer Trend)
input int             InpSignalDepth  = 3;          // Swing-Depth Signal (Kerzen je Seite)
input int             InpFilterDepth  = 3;          // Swing-Depth Filter (Kerzen je Seite)
input int             InpTrendSwingsX = 5;          // x: Swings fuer Filter-Trend
input int             InpSignalSwingsY= 5;          // y: Swings fuer Signal-Einstieg

//--- Eingaben: Handel ----------------------------------------------
input group "--- Handel ---"
input int             InpMaxTradesPerTrend = 1;     // max. Einstiege pro Filter-Trend
input double          InpRiskMoney    = 10.0;       // Risiko pro Trade (Kontowaehrung)

enum ENUM_DIST_MODE { DIST_POINTS = 0, DIST_PERCENT = 1 };
input group "--- Stop-Loss ---"
input bool            InpSLatLastSwing= true;       // SL am letzten Swing-Punkt (statt fester Distanz)
input ENUM_DIST_MODE  InpSLMode       = DIST_POINTS;// falls nicht Swing: Punkte oder %
input double          InpSLValue      = 300;        // SL-Wert (Punkte oder % vom Einstieg)

input group "--- Take-Profit ---"
input bool            InpUseTP        = true;       // Take-Profit verwenden?
input ENUM_DIST_MODE  InpTPMode       = DIST_POINTS;// Punkte oder %
input double          InpTPValue      = 600;        // TP-Wert (Punkte oder % vom Einstieg)

//--- Eingaben: Visualisierung --------------------------------------
input group "--- Visualisierung ---"
input bool            InpShowSwings   = true;       // Swing-Punkte zeichnen
input bool            InpShowTrendLines = true;     // Trend-Linien zeichnen
input bool            InpShowRects    = false;      // Rechtecke zeichnen
input color           InpSigHighColor = clrTomato;  // Signal Swing-Hoch
input color           InpSigLowColor  = clrDodgerBlue; // Signal Swing-Tief
input color           InpFilHighColor = clrRed;     // Filter Swing-Hoch
input color           InpFilLowColor  = clrLime;    // Filter Swing-Tief

//--- Eingaben: System ----------------------------------------------
input group "--- System ---"
input ulong           InpMagic        = 770010;     // Magic Number
input int             InpSlippage     = 5;          // max. Slippage (Punkte)

//--- Swing-Datenstruktur -------------------------------------------
struct Swing
  {
   datetime time;   // Zeit der Swing-Kerze
   double   price;  // Swing-Preis (High oder Low)
   bool     isHigh; // true = Hoch, false = Tief
  };

Swing    g_sig[];             // bestaetigte Signal-Swings (alternierend)
Swing    g_fil[];             // bestaetigte Filter-Swings (alternierend)
datetime g_sigLastBar = 0;    // zuletzt verarbeitete Signal-Kerze
datetime g_filLastBar = 0;    // zuletzt verarbeitete Filter-Kerze

int      g_trend       = 0;   // aktueller Filter-Trend: 1 auf, -1 ab, 0 keiner
int      g_tradesTrend = 0;   // Einstiege im aktuellen Trend
datetime g_lastEntryBar= 0;   // letzte Signal-Kerze mit Einstieg (Anti-Doppel)
string   g_prefix      = "SSEA_"; // Praefix fuer Chart-Objekte

//+------------------------------------------------------------------+
//| Initialisierung                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpSignalDepth < 1 || InpFilterDepth < 1 || InpTrendSwingsX < 2 || InpSignalSwingsY < 2)
     {
      Print("Fehler: Depth >=1 und Swings-x/y >=2 noetig.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);

   g_sigLastBar = 0; g_filLastBar = 0;
   g_trend = 0; g_tradesTrend = 0; g_lastEntryBar = 0;
   ArrayResize(g_sig, 0);
   ArrayResize(g_fil, 0);

   // Historische Swings einmalig aufbauen (aus geschlossenen Kerzen)
   BuildHistory(InpFilterTF, InpFilterDepth, g_fil, false);
   BuildHistory(InpSignalTF, InpSignalDepth, g_sig, true);
   g_trend = EvaluateTrend(g_fil, InpTrendSwingsX);

   Print("Struktur-Swing-EA gestartet. Signal ", EnumToString(InpSignalTF),
         " (Depth ", InpSignalDepth, "), Filter ", EnumToString(InpFilterTF),
         " (Depth ", InpFilterDepth, "). Start-Trend ", g_trend);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Aufraeumen: eigene Chart-Objekte entfernen                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, g_prefix);
  }

//+------------------------------------------------------------------+
//| Haupt-Tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1) Neue Filter-Kerze? -> Filter-Swing + Trend aktualisieren
   datetime fbar = iTime(_Symbol, InpFilterTF, 0);
   if(fbar != g_filLastBar)
     {
      g_filLastBar = fbar;
      DetectNewSwing(InpFilterTF, InpFilterDepth, g_fil, false);
      UpdateTrendAndExits();
     }

   // 2) Neue Signal-Kerze? -> Signal-Swing + ggf. Einstieg
   datetime sbar = iTime(_Symbol, InpSignalTF, 0);
   if(sbar != g_sigLastBar)
     {
      g_sigLastBar = sbar;
      bool newSwing = DetectNewSwing(InpSignalTF, InpSignalDepth, g_sig, true);
      if(newSwing)
         TryEntry();
     }
  }

//+------------------------------------------------------------------+
//| Baut die Swing-Historie einmalig aus geschlossenen Kerzen auf    |
//+------------------------------------------------------------------+
void BuildHistory(ENUM_TIMEFRAMES tf, int depth, Swing &arr[], bool isSignal)
  {
   int bars = iBars(_Symbol, tf);
   int maxScan = MathMin(bars - depth - 1, 500); // Historie begrenzen
   // aelteste zuerst: Kandidat bei shift c ist bestaetigt, wenn depth Kerzen
   // rechts (juenger) geschlossen sind -> c laeuft von (maxScan) bis (depth+1)
   for(int c = maxScan; c >= depth + 1; c--)
      EvalCandidate(tf, depth, c, arr, isSignal);
  }

//+------------------------------------------------------------------+
//| Prueft die neu bestaetigbare Kerze (Kandidat bei shift depth+1)  |
//| Rueckgabe true, wenn ein neuer Swing hinzugefuegt/aktualisiert   |
//+------------------------------------------------------------------+
bool DetectNewSwing(ENUM_TIMEFRAMES tf, int depth, Swing &arr[], bool isSignal)
  {
   int before = ArraySize(arr);
   double lastPrice = (before > 0) ? arr[before-1].price : 0.0;
   bool   lastHigh  = (before > 0) ? arr[before-1].isHigh : false;
   EvalCandidate(tf, depth, depth + 1, arr, isSignal);
   int after = ArraySize(arr);
   if(after != before) return(true);
   // auch "gleicher Typ aktualisiert" zaehlt als Aenderung
   if(after > 0 && (arr[after-1].price != lastPrice || arr[after-1].isHigh != lastHigh))
      return(true);
   return(false);
  }

//+------------------------------------------------------------------+
//| Bewertet die Kerze bei shift c als Fractal-Hoch/-Tief und haengt |
//| sie ggf. an das (alternierende) Swing-Array an.                  |
//+------------------------------------------------------------------+
void EvalCandidate(ENUM_TIMEFRAMES tf, int depth, int c, Swing &arr[], bool isSignal)
  {
   double hc = iHigh(_Symbol, tf, c);
   double lc = iLow(_Symbol, tf, c);
   if(hc <= 0.0 || lc <= 0.0) return;

   bool isHigh = true, isLow = true;
   for(int k = 1; k <= depth; k++)
     {
      double hR = iHigh(_Symbol, tf, c-k), hL = iHigh(_Symbol, tf, c+k);
      double lR = iLow(_Symbol, tf, c-k),  lL = iLow(_Symbol, tf, c+k);
      if(hR <= 0 || hL <= 0 || lR <= 0 || lL <= 0) { isHigh=false; isLow=false; break; }
      if(hc <= hR || hc <= hL) isHigh = false;
      if(lc >= lR || lc >= lL) isLow  = false;
     }
   if(!isHigh && !isLow) return;

   // Falls eine Kerze beides waere: als Hoch werten (selten).
   Swing s;
   s.time   = iTime(_Symbol, tf, c);
   s.isHigh = isHigh;
   s.price  = isHigh ? hc : lc;

   AppendSwing(arr, s, isSignal);
  }

//+------------------------------------------------------------------+
//| Fuegt Swing an; haelt die Folge alternierend (H,L,H,L...):       |
//| gleicher Typ -> nur behalten, wenn extremer (hoeheres Hoch /     |
//| tieferes Tief), sonst verwerfen.                                 |
//+------------------------------------------------------------------+
void AppendSwing(Swing &arr[], Swing &s, bool isSignal)
  {
   int n = ArraySize(arr);
   if(n > 0 && arr[n-1].time == s.time) return; // schon verarbeitet

   if(n > 0 && arr[n-1].isHigh == s.isHigh)
     {
      bool moreExtreme = s.isHigh ? (s.price > arr[n-1].price) : (s.price < arr[n-1].price);
      if(!moreExtreme) return;
      arr[n-1] = s;               // extremeren Punkt uebernehmen
      DrawSwing(s, isSignal, n-1);
      return;
     }
   ArrayResize(arr, n+1);
   arr[n] = s;
   DrawSwing(s, isSignal, n);
  }

//+------------------------------------------------------------------+
//| Zerlegt Swing-Array in Hoch- und Tief-Serie (chronologisch)      |
//+------------------------------------------------------------------+
void SplitHL(Swing &arr[], double &highs[], double &lows[])
  {
   int n = ArraySize(arr), nh=0, nl=0;
   ArrayResize(highs, 0); ArrayResize(lows, 0);
   for(int i=0; i<n; i++)
     {
      if(arr[i].isHigh) { ArrayResize(highs, nh+1); highs[nh++] = arr[i].price; }
      else              { ArrayResize(lows,  nl+1); lows[nl++]  = arr[i].price; }
     }
  }

//+------------------------------------------------------------------+
//| Zaehlt am Ende der Serie aufeinanderfolgende steigende (dir=1)   |
//| bzw. fallende (dir=-1) Werte (Anzahl der "Schritte")             |
//+------------------------------------------------------------------+
int CountConsec(double &v[], int dir)
  {
   int n = ArraySize(v);
   int cnt = 0;
   for(int i=n-1; i>=1; i--)
     {
      if(dir>0 && v[i] > v[i-1]) cnt++;
      else if(dir<0 && v[i] < v[i-1]) cnt++;
      else break;
     }
   return(cnt);
  }

//+------------------------------------------------------------------+
//| Bewertet Trend aus einem Swing-Array: +1 auf, -1 ab, 0 keiner    |
//| (x aufeinanderfolgende hoehere Hochs UND hoehere Tiefs = auf)    |
//+------------------------------------------------------------------+
int EvaluateTrend(Swing &arr[], int x)
  {
   double highs[], lows[];
   SplitHL(arr, highs, lows);
   if(CountConsec(highs, 1) >= x-1 && CountConsec(lows, 1) >= x-1 &&
      ArraySize(highs) >= x && ArraySize(lows) >= x)
      return(1);
   if(CountConsec(highs, -1) >= x-1 && CountConsec(lows, -1) >= x-1 &&
      ArraySize(highs) >= x && ArraySize(lows) >= x)
      return(-1);
   return(0);
  }

//+------------------------------------------------------------------+
//| Letztes Swing-Hoch / -Tief eines Arrays (0 wenn keins)           |
//+------------------------------------------------------------------+
double LastSwing(Swing &arr[], bool wantHigh)
  {
   for(int i=ArraySize(arr)-1; i>=0; i--)
      if(arr[i].isHigh == wantHigh) return(arr[i].price);
   return(0.0);
  }

//+------------------------------------------------------------------+
//| Filter-Trend aktualisieren + Ausstiege bei Trendbruch            |
//+------------------------------------------------------------------+
void UpdateTrendAndExits()
  {
   int newTrend = EvaluateTrend(g_fil, InpTrendSwingsX);

   // Bruch pruefen: Schlusskurs der letzten geschlossenen Filter-Kerze
   double closeF = iClose(_Symbol, InpFilterTF, 1);
   if(g_trend == 1)
     {
      double lastLow = LastSwing(g_fil, false);
      if(lastLow > 0 && closeF < lastLow) newTrend = 0; // Auf-Trend gebrochen
      else if(newTrend != -1) newTrend = 1;             // laeuft weiter
     }
   else if(g_trend == -1)
     {
      double lastHigh = LastSwing(g_fil, true);
      if(lastHigh > 0 && closeF > lastHigh) newTrend = 0;
      else if(newTrend != 1) newTrend = -1;
     }

   if(newTrend != g_trend)
     {
      // Richtung verlassen -> zugehoerige Positionen schliessen
      if(g_trend == 1) CloseAll(POSITION_TYPE_BUY);
      if(g_trend == -1) CloseAll(POSITION_TYPE_SELL);
      g_trend = newTrend;
      g_tradesTrend = 0;          // Zaehler fuer neuen Trend zuruecksetzen
      DrawTrendLines();
     }
  }

//+------------------------------------------------------------------+
//| Einstieg pruefen (nur bei neuer Signal-Kerze mit neuem Swing)    |
//+------------------------------------------------------------------+
void TryEntry()
  {
   if(g_trend == 0) return;
   if(g_tradesTrend >= InpMaxTradesPerTrend) return;
   if(g_lastEntryBar == g_sigLastBar) return; // pro Kerze nur einmal

   int sigTrend = EvaluateTrend(g_sig, InpSignalSwingsY);
   if(sigTrend != g_trend) return;            // Signal muss zum Filter passen

   bool isLong = (g_trend == 1);
   if(OpenPosition(isLong))
     {
      g_tradesTrend++;
      g_lastEntryBar = g_sigLastBar;
     }
  }

//+------------------------------------------------------------------+
//| Position oeffnen mit dynamischem Lot, SL/TP nach Eingaben        |
//+------------------------------------------------------------------+
bool OpenPosition(bool isLong)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry = isLong ? ask : bid;
   double point = _Point;

   // --- SL-Distanz bestimmen ---
   double slDist = 0.0;
   if(InpSLatLastSwing)
     {
      double sw = isLong ? LastSwing(g_sig, false) : LastSwing(g_sig, true);
      if(sw > 0) slDist = MathAbs(entry - sw);
     }
   if(slDist <= 0.0) // Fallback / feste Distanz
     {
      slDist = (InpSLMode == DIST_POINTS) ? InpSLValue * point
                                          : entry * InpSLValue / 100.0;
     }
   double stopsLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   if(slDist < stopsLevel) slDist = stopsLevel + point;
   if(slDist <= 0.0) { Print("Ungueltige SL-Distanz."); return(false); }

   double slPrice = isLong ? (entry - slDist) : (entry + slDist);

   // --- TP-Distanz (optional) ---
   double tpPrice = 0.0;
   if(InpUseTP)
     {
      double tpDist = (InpTPMode == DIST_POINTS) ? InpTPValue * point
                                                 : entry * InpTPValue / 100.0;
      if(tpDist < stopsLevel) tpDist = stopsLevel + point;
      tpPrice = isLong ? (entry + tpDist) : (entry - tpDist);
     }

   double lots = LotForRisk(isLong, entry, slDist);
   if(lots <= 0.0) { Print("Lot 0 - kein Einstieg."); return(false); }

   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);

   bool ok = isLong ? trade.Buy(lots, _Symbol, ask, slPrice, tpPrice, "SwingEA")
                    : trade.Sell(lots, _Symbol, bid, slPrice, tpPrice, "SwingEA");
   if(!ok)
      Print("Order fehlgeschlagen: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   else
      Print((isLong?"LONG":"SHORT"), " ", DoubleToString(lots,2), " Lot, SL ",
            DoubleToString(slPrice,_Digits), " Risk ", DoubleToString(InpRiskMoney,2));
   return(ok);
  }

//+------------------------------------------------------------------+
//| Lot so, dass ein SL-Treffer InpRiskMoney kostet (OrderCalcProfit)|
//+------------------------------------------------------------------+
double LotForRisk(bool isLong, double entry, double slDist)
  {
   double exit = isLong ? (entry - slDist) : (entry + slDist);
   ENUM_ORDER_TYPE ot = isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double lossPerLot = 0.0;
   if(OrderCalcProfit(ot, _Symbol, 1.0, entry, exit, lossPerLot))
      lossPerLot = MathAbs(lossPerLot);
   else
      lossPerLot = 0.0;
   if(lossPerLot <= 0.0)
     {
      double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(ts <= 0 || tv <= 0) return(0.0);
      lossPerLot = (slDist / ts) * tv;
     }
   if(lossPerLot <= 0.0) return(0.0);

   double lots   = InpRiskMoney / lossPerLot;
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step > 0) lots = MathFloor(lots/step)*step;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return(lots);
  }

//+------------------------------------------------------------------+
//| Alle Positionen dieses EA einer Richtung schliessen              |
//+------------------------------------------------------------------+
void CloseAll(ENUM_POSITION_TYPE type)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;
      trade.PositionClose(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Zeichnet einen Swing-Punkt (Pfeil, kein Text)                    |
//+------------------------------------------------------------------+
void DrawSwing(Swing &s, bool isSignal, int idx)
  {
   if(!InpShowSwings) return;
   string name = g_prefix + (isSignal?"S":"F") + IntegerToString((int)s.time) +
                 (s.isHigh?"H":"L");
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, s.time, s.price);
   // Pfeil-Codes: 234 = runter (ueber Hoch), 233 = hoch (unter Tief)
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, s.isHigh ? 234 : 233);
   color c;
   if(isSignal) c = s.isHigh ? InpSigHighColor : InpSigLowColor;
   else         c = s.isHigh ? InpFilHighColor : InpFilLowColor;
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, isSignal ? 1 : 2);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, s.isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
  }

//+------------------------------------------------------------------+
//| Zeichnet Trend-Linien (verbindet die letzten Filter-Swings)      |
//| und optional Rechtecke zwischen den Punkten.                     |
//+------------------------------------------------------------------+
void DrawTrendLines()
  {
   if(!InpShowTrendLines && !InpShowRects) return;
   int n = ArraySize(g_fil);
   if(n < 2) return;
   int fromIdx = MathMax(0, n - (2*InpTrendSwingsX));
   for(int i=fromIdx; i<n-1; i++)
     {
      if(InpShowTrendLines)
        {
         string ln = g_prefix + "TL" + IntegerToString(i);
         if(ObjectFind(0, ln) < 0)
            ObjectCreate(0, ln, OBJ_TREND, 0, g_fil[i].time, g_fil[i].price,
                                              g_fil[i+1].time, g_fil[i+1].price);
         else
           {
            ObjectMove(0, ln, 0, g_fil[i].time, g_fil[i].price);
            ObjectMove(0, ln, 1, g_fil[i+1].time, g_fil[i+1].price);
           }
         ObjectSetInteger(0, ln, OBJPROP_COLOR, g_trend==1?InpFilLowColor:InpFilHighColor);
         ObjectSetInteger(0, ln, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, ln, OBJPROP_RAY_RIGHT, false);
        }
      if(InpShowRects)
        {
         string rc = g_prefix + "RC" + IntegerToString(i);
         double p1 = g_fil[i].price, p2 = g_fil[i+1].price;
         if(ObjectFind(0, rc) < 0)
            ObjectCreate(0, rc, OBJ_RECTANGLE, 0, g_fil[i].time, p1, g_fil[i+1].time, p2);
         else
           {
            ObjectMove(0, rc, 0, g_fil[i].time, p1);
            ObjectMove(0, rc, 1, g_fil[i+1].time, p2);
           }
         ObjectSetInteger(0, rc, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(0, rc, OBJPROP_BACK, true);
        }
     }
  }
//+------------------------------------------------------------------+
