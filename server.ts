import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = 3000;

app.use(express.json());

// Lazy-loaded Gemini AI Client
let aiClient: any = null;

function getGeminiClient() {
  if (!aiClient) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY_MISSING");
    }
    aiClient = new GoogleGenAI({
      apiKey: apiKey,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      }
    });
  }
  return aiClient;
}

// API: Check status & API key presence
app.get("/api/status", (req, res) => {
  const hasKey = !!process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY !== "MY_GEMINI_API_KEY";
  res.json({
    status: "ok",
    hasApiKey: hasKey,
    environment: process.env.NODE_ENV || "development"
  });
});

// API: Analyze MT5 backtest metrics and provide strategy refinement suggestions
app.post("/api/analyze-backtest", async (req, res) => {
  try {
    const { metrics, eaCode } = req.body;
    
    if (!metrics) {
      res.status(400).json({ error: "Backtest-Kennzahlen sind erforderlich." });
      return;
    }

    let ai;
    try {
      ai = getGeminiClient();
    } catch (err: any) {
      if (err.message === "GEMINI_API_KEY_MISSING") {
        res.status(400).json({
          error: "API_KEY_MISSING",
          message: "Der GEMINI_API_KEY ist nicht in den Secrets hinterlegt. Bitte fuegen Sie den Key im Secrets-Panel (Settings > Secrets) hinzu, um die AI-Analyse freizuschalten."
        });
        return;
      }
      throw err;
    }

    const prompt = `Du bist ein professioneller Quant-Trader, Risikomanager und MQL5-Programmierer fuer MetaTrader 5.
Ein Nutzer bittet dich, seine Backtest-Ergebnisse fuer den MQL5 Expert Advisor (EMA-9/21-Crossover Long-Only) zu analysieren und Optimierungsvorschlaege zu machen.

Hier sind die eingegebenen Backtest-Ergebnisse:
${JSON.stringify(metrics, null, 2)}

Hier ist der aktuelle MQL5 Quellcode des EA:
${eaCode || "// Kein Code uebergeben, benutze den Standard-EA"}

Analysiere diese Werte im Kontext des Startkapitals von 1.000 EUR und dem Hebel von 1:30 auf dem Forex-Markt (EURUSD).
Achte besonders darauf, ob der maximale Drawdown im Verhaeltnis zum Guthaben zu hoch ist und ob das Lot-Volumen (0.1 Lots) fuer 1.000 EUR zu riskant ist.

Liefere deine gesamte Antwort im JSON-Format gemaess dem bereitgestellten Schema. Verwende fuer deutsche Texte grundsaetzlich KEINE Umlaute (ae statt ä, oe statt ö, ue statt ü, ss statt ß), damit die Ausgabe vollkommen kompatibel mit dem MetaEditor Zeichensatz bleibt und keine Darstellungsfehler auftreten!`;

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        systemInstruction: "Du bist ein praeziser, technischer Berater fuer quantitatives Trading. Du sprichst Deutsch, vermeidest jedoch jegliche Umlaute (ä, ö, ü, ß) und ersetzt sie durch ae, oe, ue, ss. Du lieferst stets gueltiges JSON gemaess dem Schema.",
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            evaluation: {
              type: Type.STRING,
              description: "Eine detaillierte quantitative Bewertung der Performance-Kennzahlen in verstaendlichem Deutsch (ohne Umlaute)."
            },
            riskAssessment: {
              type: Type.STRING,
              description: "Eine kritische Analyse des Risikos, Drawdowns und der Lot-Size im Verhaeltnis zur Hebelwirkung (ohne Umlaute)."
            },
            suggestions: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "Liste von 3 bis 5 konkreten, umsetzbaren Verbesserungsvorschlaegen (ohne Umlaute)."
            },
            refinedCodeSnippet: {
              type: Type.STRING,
              description: "Ein vollstaendiger MQL5 Code-Abschnitt (z.B. Trailing Stop, ATR-basierter SL oder ein Volumen-Filter) mit deutschen Kommentaren (ohne Umlaute), der einen Vorschlag direkt implementiert."
            }
          },
          required: ["evaluation", "riskAssessment", "suggestions", "refinedCodeSnippet"]
        }
      }
    });

    const responseText = response.text;
    if (!responseText) {
      throw new Error("Leere Antwort von Gemini erhalten.");
    }

    const result = JSON.parse(responseText);
    res.json(result);

  } catch (error: any) {
    console.error("Fehler bei der Backtest-Analyse:", error);
    res.status(500).json({
      error: "SERVER_ERROR",
      message: "Ein interner Fehler ist bei der AI-Analyse aufgetreten: " + error.message
    });
  }
});

// Serve the actual raw .mq5 file for direct download
app.get("/api/download-ea", (req, res) => {
  // Read code parameters from query
  const fast = req.query.fastEMA || "9";
  const slow = req.query.slowEMA || "21";
  const lot = req.query.lotSize || "0.1";
  const sl = req.query.stopLoss || "2.0";
  const tp = req.query.takeProfit || "4.0";
  const dailyLimit = req.query.dailyLimit || "5.0";

  // Let's load the template code (or generate it dynamically with the user's choices)
  const template = `//+------------------------------------------------------------------+
//|                                    ema_crossover_customizer.mq5  |
//|                                Philipp Behnisch / Trading Studio |
//|                                             https://ai.studio/   |
//+------------------------------------------------------------------+
#property copyright "Philipp Behnisch / Trading Studio"
#property link      "https://ai.studio/"
#property version   "1.00"
#property description "EMA-${fast}/${slow}-Crossover Long-Only Expert Advisor"
#property description "DYNAMISCH GENERIERT im MT5 MQL5 EA Studio."

// Trade-Bibliothek importieren
#include <Trade\\Trade.mqh>
CTrade trade;

//--- Input Parameter
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = ${fast};       // Perioden schnelle EMA
input int      InpSlowEMAPeriod  = ${slow};      // Perioden langsame EMA

input group "--- Trend-Filter ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)

input group "--- Risikomanagement ---"
input double   InpLotSize        = ${lot};     // Handelsvolumen (Lots)
input double   InpStopLossPct    = ${sl};     // Stop-Loss in % vom Kontostand
input double   InpTakeProfitPct  = ${tp};     // Take-Profit in % vom Kontostand
input double   InpDailyLossLimit = ${dailyLimit};     // Tagesverlust-Limit in % vom Kontostand

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

   m_last_bar_time     = 0;
   m_loss_limit_active = false;
   
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("EA erfolgreich initialisiert.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(h_fastEMA);
   IndicatorRelease(h_slowEMA);
   if(h_trendEMA != INVALID_HANDLE)
     {
      IndicatorRelease(h_trendEMA);
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
   if(current_time.day_of_year != m_last_day)
     {
      m_last_day          = current_time.day_of_year;
      m_loss_limit_active = false;
      m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
     }

   if(CheckDailyLossLimit())
     {
      if(!m_loss_limit_active)
        {
         m_loss_limit_active = true;
         CloseAllPositions();
        }
      return;
     }

   datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(current_bar_time == m_last_bar_time)
     {
      return;
     }

   double fastEMA[3];
   double slowEMA[3];
   double trendEMA[3];

   if(CopyBuffer(h_fastEMA, 0, 0, 3, fastEMA) < 3 ||
      CopyBuffer(h_slowEMA, 0, 0, 3, slowEMA) < 3)
     {
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

   m_last_bar_time = current_bar_time;

   bool isGoldenCross = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   bool isDeathCross  = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   // Trend-Bedingung: Nur kaufen, wenn die schnelle EMA ueber der Trend-EMA liegt (Aufwaertstrend)
   bool isTrendUp = true;
   if(InpUseTrendFilter && h_trendEMA != INVALID_HANDLE)
     {
      isTrendUp = (fastEMA[1] > trendEMA[1]);
     }

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

   if(hasOpenPosition)
     {
      if(isDeathCross)
        {
         trade.PositionClose(ticket);
        }
     }
   else
     {
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
   double daily_pnl = current_equity - m_day_start_balance;
   
   if(daily_pnl < 0)
     {
      double loss_percent = (MathAbs(daily_pnl) / m_day_start_balance) * 100.0;
      if(loss_percent >= InpDailyLossLimit)
        {
         return true;
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
   
   double risk_amount = balance * (InpStopLossPct / 100.0);
   double profit_amount = balance * (InpTakeProfitPct / 100.0);
   
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tick_size <= 0 || tick_value <= 0) return;
     
   double sl_distance = (risk_amount / (InpLotSize * tick_value)) * tick_size;
   double tp_distance = (profit_amount / (InpLotSize * tick_value)) * tick_size;
   
   double sl_price = NormalizeDouble(ask - sl_distance, _Digits);
   double tp_price = NormalizeDouble(ask + tp_distance, _Digits);

   trade.Buy(InpLotSize, _Symbol, ask, sl_price, tp_price, "EMA Crossover Long (Custom)");
  }
`;

  res.setHeader("Content-Type", "application/octet-stream");
  res.setHeader("Content-Disposition", `attachment; filename=ema_${fast}_${slow}_crossover_long.mq5`);
  res.send(template);
});

// Setup Vite Development Server or Production Static Serving
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
